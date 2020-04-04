module TelegramWorkflow
  class << self
    attr_accessor :config

    def configure
      @config ||= Configuration.new
      yield(@config)
      @__after_configuration.call
    end

    def __after_configuration(&block)
      @__after_configuration = block
    end
  end

  class Configuration
    attr_accessor :session_store, :logger, :client, :start_action, :webhook_url, :api_token

    def initialize
      @session_store = Rails.cache
      @logger = Rails.logger
      @client = TelegramWorkflow::Client
    end
  end
end
