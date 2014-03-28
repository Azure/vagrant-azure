#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the Apache 2.0 License.
#--------------------------------------------------------------------------

require "#{Vagrant::source_root}/lib/vagrant/util/which"
require "#{Vagrant::source_root}/lib/vagrant/util/subprocess"

module Vagrant
  module Util
    # Executes PowerShell scripts.
    #
    # This is primarily a convenience wrapper around Subprocess that
    # properly sets powershell flags for you.
    class PowerShell
      # Monkey patch to fix a bug with Vagrant 1.5.1.
      # https://github.com/mitchellh/vagrant/issues/3192.
      # This has been fixed in 1.5.2. by
      # https://github.com/jyggen/vagrant/commit/d7320399e2497aae9b9c3fa83d94b7210d21bfb5
      def self.execute(path, *args, **opts, &block)
        command = [
          "powershell",
          "-NoProfile",
          "-ExecutionPolicy", "Bypass",
          "&('#{path}')",
          args
        ].flatten

        # Append on the options hash since Subprocess doesn't use
        # Ruby 2.0 style options yet.
        command << opts

        Subprocess.execute(*command, &block)
      end
    end
  end
end
