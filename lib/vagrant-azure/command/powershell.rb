module VagrantPlugins
  module WinAzure
    module Command
      class PowerShell < Vagrant.plugin('2', :command)
        def self.synopsis
          'execute PowerShell command or script on remote machine'
        end

        def execute
          options = {}

          opts = OptionParser.new do |o|
            o.banner = 'Usage: vagrant powershell [machine] -[c|s] [command|script file]'
            o.separator ''
            o.separator 'Options:'
            o.separator ''

            o.on('-c', '--command COMMAND', 'Execute a PowerShell command directly') do |c|
              options[:command] = c
            end

            o.on('-s', '--script SCRIPT_FILE', 'Execute a PowerShell script directly') do |s|
              raise Vagrant::Errors::CLIInvalidOptions, :help => "File #{s} can't be found. Does it exist?" unless File.exists?(s)
              options[:command] = File.read(s)
            end
          end

          argv = parse_options(opts)
          if options.empty?
            raise Vagrant::Errors::CLIInvalidOptions, :help => opts.help.chomp
          end

          with_target_vms(argv, single_target: true) do |vm|
            @logger.debug("Executing single command on remote machine: #{options[:command]}")

            vm.action(:powershell_run, powershell_command: options[:command])
          end
          0
        end
      end
    end
  end
end
