module TelegramWorkflow
  class << self
    attr_accessor :config

    def configure
      @config ||= Configuration.new
      yield(@config)
    end
  end

  class Configuration
    attr_accessor :session_store, :logger, :client, :start_action, :webhook_url, :api_token
  end
end
