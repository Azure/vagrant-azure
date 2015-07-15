VagrantPlugins::CommunicatorWinRM::WinRMShell.class_eval do
  def endpoint_options
    {user: @username,
     pass: @password,
     host: @host,
     port: @port,
     basic_auth_only: false,
     no_ssl_peer_verification: !@config.ssl_peer_verification,
     disable_sspi: true
    }
  end
end