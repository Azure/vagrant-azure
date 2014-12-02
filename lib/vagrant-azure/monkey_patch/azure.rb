
require 'azure'

Azure::VirtualMachineManagement::Serialization.module_eval do
  def self.role_to_xml(params, options)
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.PersistentVMRole(
        'xmlns' => 'http://schemas.microsoft.com/windowsazure',
        'xmlns:i' => 'http://www.w3.org/2001/XMLSchema-instance'
      ) do
        xml.RoleName { xml.text params[:vm_name] }
        xml.OsVersion('i:nil' => 'true')
        xml.RoleType 'PersistentVMRole'

        xml.ConfigurationSets do
          provisioning_configuration_to_xml(xml, params, options)
          xml.ConfigurationSet('i:type' => 'NetworkConfigurationSet') do
            xml.ConfigurationSetType 'NetworkConfiguration'
            xml.InputEndpoints do
              default_endpoints_to_xml(xml, options)
              tcp_endpoints_to_xml(
                xml,
                options[:tcp_endpoints],
                options[:existing_ports]
              ) if options[:tcp_endpoints]
            end
            if options[:virtual_network_name] && options[:subnet_name]
              xml.SubnetNames do
                xml.SubnetName options[:subnet_name]
              end
            end
          end
        end
        xml.AvailabilitySetName options[:availability_set_name]
        xml.Label Base64.encode64(params[:vm_name]).strip
        xml.OSVirtualHardDisk do
          xml.MediaLink 'http://' + options[:storage_account_name] + '.blob.core.windows.net/vhds/' + (Time.now.strftime('disk_%Y_%m_%d_%H_%M_%S_%L')) + '.vhd'
          xml.SourceImageName params[:image]
        end
        xml.RoleSize options[:vm_size]
      end
    end
    builder.doc
  end
end