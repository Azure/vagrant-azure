module VagrantPlugins
  module WinAzure
    module Action
      class PowerShellRun
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_azure::action::powershell_run_command')
        end

        def call(env)

          if env[:machine].communicate.ready?
            env[:machine].ui.detail("PowerShell Executing: #{env[:powershell_command]}")
            env[:powershell_command_exit_status] = env[:machine].communicate.execute(env[:powershell_command]) do |type, stream|
              if type == :stdout
                env[:machine].ui.success(stream) unless (stream || '').chomp.empty?
              else
                env[:machine].ui.error(stream) unless (stream || '').chomp.empty?
              end
            end
          end

          @app.call(env)
        end
      end
    end
  end
end
