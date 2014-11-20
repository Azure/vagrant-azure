module VagrantPlugins
  module WinAzure
    module Cap
      class WinRM
        def self.winrm_info(machine)
          env = machine.action('read_winrm_info')
          env[:machine_winrm_info]
        end
      end
    end
  end
end