# Copyright (c) 2014 Mitchell Hashimoto
# Under The MIT License (MIT)
#---------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved.  Licensed under the Apache License, Version 2.0.
# See License.txt in the project root for license information.
#--------------------------------------------------------------------------
require "log4r"
require "vagrant/util/subprocess"
require "vagrant/util/scoped_hash_override"
require "vagrant/util/which"
require "#{Vagrant::source_root}/lib/vagrant/action/builtin/synced_folders"

module VagrantPlugins
  module WinAzure
    module Action
      # This middleware uses `rsync` to sync the folders
      class SyncFolders < Vagrant::Action::Builtin::SyncedFolders
        include Vagrant::Util::ScopedHashOverride

        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_azure::action::sync_folders")
        end

        def call(env)
          if env[:machine].config.vm.guest != :windows
            super
          else
            @app.call(env)
            env[:machine].config.vm.synced_folders.each do |id, data|
              data = scoped_hash_override(data, :azure)

              # Ignore disabled shared folders
              next if data[:disabled]

              hostpath  = File.expand_path(data[:hostpath], env[:root_path])
              guestpath = data[:guestpath]

              env[:ui].info(I18n.t("vagrant_azure.copy_folder",
                                  :hostpath => hostpath,
                                  :guestpath => guestpath))

              # Create the host path if it doesn't exist and option flag is set
              if data[:create]
                begin
                  FileUtils::mkdir_p(hostpath)
                rescue => err
                  raise Errors::MkdirError,
                    :hostpath => hostpath,
                    :err => err
                end
              end

              env[:machine].communicate.upload(hostpath, guestpath)

            end
          end
        end

      end
    end
  end
end
