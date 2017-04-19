# encoding: utf-8
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License in the project root for license information.

require "spec_helper"
require "vagrant-azure/util/template_renderer"

module VagrantPlugins
  module Azure
    describe "deployment template" do

      let(:options) {
        {
            operating_system: "linux",
            location: "location",
            endpoints: [22],
            data_disks: []
        }
      }

      describe "the basics" do
        let(:subject) {
          render(options)
        }

        it "should specify schema" do
          expect(subject["$schema"]).to eq("http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json")
        end

        it "should specify content version" do
          expect(subject["contentVersion"]).to eq("1.0.0.0")
        end

        it "should have 10 parameters" do
          expect(subject["parameters"].count).to eq(10)
        end

        it "should have 14 variables" do
          expect(subject["variables"].count).to eq(14)
        end

        it "should have 5 resources" do
          expect(subject["resources"].count).to eq(5)
        end
      end

      describe "resources" do
        describe "virtual machine" do
          let(:subject) {
            render(options)["resources"].detect {|vm| vm["type"] == "Microsoft.Compute/virtualMachines"}
          }

          it "should depend on 1 resources without an AV Set" do
            expect(subject["dependsOn"].count).to eq(1)
          end

          describe "with AV Set" do
            let(:subject) {
              template = render(options.merge(availability_set_name: "avSet"))
              template["resources"].detect {|vm| vm["type"] == "Microsoft.Compute/virtualMachines"}
            }

            it "should depend on 2 resources with an AV Set" do
              expect(subject["dependsOn"].count).to eq(2)
            end
          end

          describe "with managed disk reference" do
            let(:subject) {
              template = render(options.merge(vm_managed_image_id: "image_id"))
              template["resources"].detect {|vm| vm["type"] == "Microsoft.Compute/virtualMachines"}
            }

            it "should have an image reference id set to image_id" do
              expect(subject["properties"]["storageProfile"]["imageReference"]["id"]).to eq("image_id")
            end
          end
        end

        describe "managed image" do
          let(:subject) {
            render(options)["resources"].detect {|vm| vm["type"] == "Microsoft.Compute/images"}
          }
          describe "with custom vhd" do
            let(:vhd_uri_options) {
              options.merge(
                  vhd_uri: "https://my_image.vhd",
                  operating_system: "Foo"
              )
            }
            let(:subject) {
              render(vhd_uri_options)["resources"].detect {|vm| vm["type"] == "Microsoft.Compute/images"}
            }

            it "should exist" do
              expect(subject).not_to be_nil
            end

            it "should set the blob_uri" do
              expect(subject["properties"]["storageProfile"]["osDisk"]["blobUri"]).to eq(vhd_uri_options[:vhd_uri])
            end

            it "should set the osType" do
              expect(subject["properties"]["storageProfile"]["osDisk"]["osType"]).to eq(vhd_uri_options[:operating_system])
            end
          end

          it "should not exist" do
            expect(subject).to be_nil
          end
        end
      end

      describe "parameters" do
        let(:base_keys) {
          %w( storageAccountType adminUserName dnsLabelPrefix nsgLabelPrefix vmSize vmName subnetName virtualNetworkName
              winRmPort )
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
          %w(location addressPrefix subnetPrefix nicName publicIPAddressName publicIPAddressType
              networkSecurityGroupName sshKeyPath vnetID subnetRef apiVersion
              singleQuote doubleQuote managedImageName)
        }

        let(:subject) {
          render(options)["variables"]
        }

        it "should include all the windows parameter keys" do
          expect(subject.keys).to contain_exactly(*keys)
        end
      end


      def render(options)
        JSON.parse(VagrantPlugins::Azure::Util::TemplateRenderer.render("arm/deployment.json", options))
      end
    end
  end
end