class TestProject
  Error = Class.new(RuntimeError)
  def initialize(&block)
    @setup_proc = block || Proc.new{}
  end

  def run
    setup!
    yield
    cleanup!
  end

  def bundle_deployment!
    run_bundler_command 'install', '--deployment'
  end

  def bundle!
    run_bundler_command 'install'
  end

  def run_bundler_command(*args)
    args.unshift 'bundler'
    args += ['--path', 'vendor']
    Bundler.with_clean_env do
      Dir.chdir @dir do
        output = IO.popen(args, err: [:child, :out]){|io|
          io.read
        }
        raise Error.new(output) unless $?.exitstatus.zero?
      end
    end
  end

  def delete_vendor!
    FileUtils.remove_entry @dir.join("vendor")
  end

  def bundle_status
    Bundler.with_clean_env do
      Dir.chdir @dir do
        status = open("|bundle show").read
        raise status unless $? == 0
        return BundlerOutputParser.new(status)
      end
    end
  end

  def has_gems_installed?
    Bundler.with_clean_env do
      Dir.chdir @dir do
        system("bundle check")
        return $? == 0
      end
    end
  end

  def has_gem?(name, version)
    bundle_status.has?(name, version)
  end

  def with_local_gemhome
    env = ENV.clone
    ENV["GEM_HOME"] = @dir.join("gems").to_s
    ENV["GEM_PATH"] = @dir.join("gems").to_s
    yield
    ENV.replace(env)
  end

  def gem_install(name, server)
    Bundler.with_clean_env do
      with_local_gemhome do
        command = ["gem", "install", name, '--clear-sources', '--source', server]
        output = IO.popen(command, err: [:child, :out]){|io| io.read }
        raise output unless $? == 0
      end
    end
  end

protected
  def setup!
    @dir = Pathname.new(Dir.mktmpdir)
    Dir.chdir @dir do
      TestProjectGemfileBuilder.call(&@setup_proc)
    end
  end

  def cleanup!
    FileUtils.remove_entry @dir
  end
end
