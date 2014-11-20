# patch no_ssl_peer_validation for ssl based winrm

WinRM::HTTP::HttpTransport.class_eval do

  # provide a patch for no peer verification.
  # the patch exists upstream, but vagrant depends on an older version of winrm
  def no_ssl_peer_verification!
    @httpcli.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end
end

WinRM::HTTP::HttpSSL.class_eval do

  # provide a constructor that offers the ability to disable peer verification
  def initialize(endpoint, user, pass, ca_trust_path = nil, opts)
    super(endpoint)
    @httpcli.set_auth(endpoint, user, pass)
    @httpcli.ssl_config.set_trust_ca(ca_trust_path) unless ca_trust_path.nil?
    no_sspi_auth! if opts[:disable_sspi]
    basic_auth_only! if opts[:basic_auth_only]
    no_ssl_peer_verification! if opts[:no_ssl_peer_verification]
  end
end


VagrantPlugins::CommunicatorWinRM::WinRMShell.class_eval do
  EXCEPTIONS = class_variable_get(:@@exceptions_to_retry_on)

  protected

  # patch the timeout being raised from openssl that is not handled properly
  def execute_shell_with_retry(command, shell, &block)
    retryable(:tries => @max_tries, :on => EXCEPTIONS, :sleep => 10) do
      @logger.debug("#{shell} executing:\n#{command}")
      begin
        output = session.send(shell, command) do |out, err|
          block.call(:stdout, out) if block_given? && out
          block.call(:stderr, err) if block_given? && err
        end
      rescue Exception => ex
        raise Timeout::Error if ex.message =~ /execution expired/ # received not friendly timeout, raise a more friendly error
        raise # didn't include execution expired, so raise for retryable to handle
      end
      @logger.debug("Output: #{output.inspect}")
      return output
    end
  end

  # create a new session using ssl rather than kerberos or plaintext
  def new_session
    @logger.info("Attempting to connect to WinRM (patched)...")
    @logger.info("  - Host: #{@host}")
    @logger.info("  - Port: #{@port}")
    @logger.info("  - Username: #{@username}")

    client = ::WinRM::WinRMWebService.new(endpoint, :ssl, endpoint_options)
    client.set_timeout(@timeout_in_seconds)
    client.toggle_nori_type_casting(:off) #we don't want coersion of types
    client
  end

  # override the internal http endpoint
  def endpoint
    "https://#{@host}:#{@port}/wsman"
  end

  # don't verify azure self signed certs and don't try to use sspi
  def endpoint_options
    {user: @username,
     pass: @password,
     host: @host,
     port: @port,
     operation_timeout: @timeout_in_seconds,
     no_ssl_peer_verification: true,
     disable_sspi: true}
  end
end