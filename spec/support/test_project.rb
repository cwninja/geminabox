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

  def bundle!
    Bundler.with_clean_env do
      Dir.chdir @dir do
        output = IO.popen(bundler_command, err: [:child, :out]){|io|
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
        command = ["gem", "install", name, '--source', server]
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

  def bundler_command
    ['bundle', 'install', '--path', 'vendor']
  end
end
