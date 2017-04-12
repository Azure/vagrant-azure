# encoding: utf-8
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License in the project root for license information.

require "spec_helper"
require "vagrant/util/template_renderer"

module VagrantPlugins
  module Azure
    describe "DeploymentTemplate" do

      let(:options) {
        {
            operating_system: "linux",
            location: "location",
            endpoints: [22],
            template_root: Azure.source_root.join("templates")
        }
      }

      describe "the basics" do
        let(:subject) {
          render(options)
        }

        it "should specify schema" do
          expect(subject["$schema"]).to eq("http://schema.management.azure.com/schemas/2014-04-01-preview/deploymentTemplate.json")
        end

        it "should specify content version" do
          expect(subject["contentVersion"]).to eq("1.0.0.0")
        end

        it "should have 13 parameters" do
          expect(subject["parameters"].count).to eq(13)
        end

        it "should have 17 variables" do
          expect(subject["variables"].count).to eq(17)
        end

        it "should have 7 resources" do
          expect(subject["resources"].count).to eq(6)
        end
      end

      describe "resources" do
        describe "the virtual machine" do
          let(:subject) {
            render(options)["resources"].detect { |vm| vm["type"] == "Microsoft.Compute/virtualMachines" }
          }

          it "should depend on 2 resources without an AV Set" do
            expect(subject["dependsOn"].count).to eq(2)
          end

          describe "with AV Set" do
            let(:subject) {
              template = render(options.merge(availability_set_name: "avSet"))
              template["resources"].detect { |vm| vm["type"] == "Microsoft.Compute/virtualMachines" }
            }

            it "should depend on 3 resources with an AV Set" do
              expect(subject["dependsOn"].count).to eq(3)
            end
          end
        end
      end

      describe "parameters" do
        let(:base_keys) {
          %w( adminUserName dnsLabelPrefix nsgLabelPrefix vmSize vmName imagePublisher imageOffer imageSku imageVersion subnetName virtualNetworkName winRmPort )
        }

        let(:nix_keys) {
          base_keys + ["sshKeyData"]
        }

        let(:subject) {
          render(options)["parameters"]
        }

        it "should include all the *nix parameter keys" do
          expect(subject.keys).to contain_exactly(*nix_keys)
        end

        describe "with Windows" do
          let(:subject) {
            render(options.merge(operating_system: "Windows"))["parameters"]
          }

          let(:win_keys) {
            base_keys + ["adminPassword"]
          }

          it "should include all the windows parameter keys" do
            expect(subject.keys).to contain_exactly(*win_keys)
          end
        end
      end

      describe "variables" do
        let(:keys) {
          %w(storageAccountName location osDiskName addressPrefix subnetPrefix vmStorageAccountContainerName nicName
              publicIPAddressName publicIPAddressType storageAccountType networkSecurityGroupName sshKeyPath vnetID
              subnetRef apiVersion singleQuote doubleQuote)
        }

        let(:subject) {
          render(options)["variables"]
        }

        it "should include all the windows parameter keys" do
          expect(subject.keys).to contain_exactly(*keys)
        end
      end


      def render(options)
        JSON.parse(Vagrant::Util::TemplateRenderer.render("arm/deployment.json", options))
      end
    end
  end
end