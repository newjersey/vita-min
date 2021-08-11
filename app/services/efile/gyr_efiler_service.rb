require 'zip'
module Efile
  class GyrEfilerService
    CURRENT_VERSION = 'ee3284a664e2fe488be71080770334bc3a1341a3'

    def self.run_efiler_command(*args)
      raise StandardError.new("Cannot be used from the test environment") if Rails.env.test?

      Dir.mktmpdir do |working_directory|
        FileUtils.mkdir_p(File.join(working_directory, "output", "log"))
        ensure_config_dir_prepared

        # TODO: If the process blocks for >10 min, terminate it.
        # TODO: Send process stdout to logs.
        # TODO: Send output/logs/ to logs after process terminates.
        classes_zip_path = Dir.glob(Rails.root.join("vendor", "gyr_efiler", "gyr-efiler-classes-#{CURRENT_VERSION}.zip"))[0]
        raise StandardError.new("You must run rails setup:download_gyr_efiler") if classes_zip_path.nil?

        config_dir = Rails.root.join("tmp", "gyr_efiler", "gyr_efiler_config").to_s

        # On macOS, "java" will show a confusing pop-up if you run it without a JVM installed. Check for that and exit early.
        if File.exists?("/Library/Java/JavaVirtualMachines") && Dir.glob("/Library/Java/JavaVirtualMachines/*").empty?
          raise StandardError.new("Seems you are on a mac & lack Java. Run: brew tap AdoptOpenJDK/openjdk && brew install adoptopenjdk8")
        end
        # /Library/Java/JavaVirtualMachines
        java = ENV["VITA_MIN_JAVA_HOME"] ? File.join(ENV["VITA_MIN_JAVA_HOME"], "bin", "java") : "java"

        argv = [java, "-cp", classes_zip_path, "org.codeforamerica.gyr.efiler.App", config_dir, *args]
        puts "Running: #{argv.inspect}"
        pid = Process.spawn(*argv,
          unsetenv_others: true,
          chdir: working_directory,
          in: "/dev/null"
        )
        Process.wait(pid)
        raise StandardError.new("Process failed to exit?") unless $?.exited?

        exit_code = $?.exitstatus
        raise StandardError.new("gyr-efiler failed; exited with #{exit_code}") if exit_code != 0

        get_single_file_from_zip(Dir.glob(File.join(working_directory, "output", "*.zip"))[0])
      end
    end

    def self.get_single_file_from_zip(zipfile_path)
      Zip::File.open(zipfile_path) do |zipfile|
        entries = zipfile.entries
        raise StandardError.new("Zip file contains more than 1 file") if entries.size != 1
        # In that case, might be good to archive the ZIP file before the working directory gets deleted

        return zipfile.read(entries.first.name)
      end
    end

    private

    def self.ensure_config_dir_prepared
      config_dir = Rails.root.join("tmp", "gyr_efiler", "gyr_efiler_config")
      FileUtils.mkdir_p(config_dir)
      return if File.exists?(File.join(config_dir, '.ready'))

      config_zip_path = Dir.glob(Rails.root.join("vendor", "gyr_efiler", "gyr-efiler-config-#{CURRENT_VERSION}.zip"))[0]
      raise StandardError.new("Please run rake setup:download_gyr_efiler then try again") if config_zip_path.nil?

      system!("unzip -o #{config_zip_path} -d #{Rails.root.join("tmp", "gyr_efiler")}")

      local_efiler_repo_config_path = File.expand_path('../gyr-efiler/gyr_efiler_config', Rails.root)
      if Rails.env.development?
        begin
          FileUtils.cp(File.join(local_efiler_repo_config_path, 'gyr_secrets.properties'), config_dir)
          FileUtils.cp(File.join(local_efiler_repo_config_path, 'secret_key_and_cert.p12.key'), config_dir)
        rescue
          raise StandardError.new("Please clone the gyr-efiler repo to ../gyr-efiler and follow its README")
        end
      else
        etin, app_sys_id, cert_base64 = config_values

        properties_content = <<~PROPERTIES
          etin=#{etin}
          app_sys_id=#{app_sys_id}
        PROPERTIES
        File.write(File.join(config_dir, 'gyr_secrets.properties'), properties_content)
        File.write(File.join(config_dir, 'secret_key_and_cert.p12.key'), Base64.decode64(cert_base64), mode: "wb")
      end

      FileUtils.touch(File.join(config_dir, '.ready'))
    end

    private

    def self.system!(*args)
      system(*args) || abort("\n== Command #{args} failed ==")
    end

    def self.config_values
      # On our Aptible environments, these config values should be in Rails secrets aka EnvironmentCredentials.
      #
      # They can also be configured by environment variables, which is convenient for local dev or manual testing.
      etin = ENV['GYR_EFILER_ETIN'].presence || EnvironmentCredentials.dig(:irs, :etin)
      app_sys_id = ENV['GYR_EFILER_APP_SYS_ID'].presence || EnvironmentCredentials.dig(:irs, :app_sys_id)
      cert_base64 = ENV['GYR_EFILER_CERT'].presence || EnvironmentCredentials.dig(:irs, :efiler_cert)
      if etin.nil? || app_sys_id.nil? || cert_base64.nil?
        raise StandardError.new("Missing etin and/or app sys id and/or cert base64 configuration")
      end

      [etin, app_sys_id, cert_base64]
    end
  end
end
