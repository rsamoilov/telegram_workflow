module TelegramWorkflow
  class << self
    attr_accessor :config

    def configure
      @config ||= Configuration.new
      yield(@config)
      @config.verify!

      @__after_configuration.call(@config)
    end

    def __after_configuration(&block)
      @__after_configuration = block
    end
  end

  class Configuration
    attr_accessor :session_store, :logger, :client, :start_action, :webhook_url, :api_token

    REQUIRED_PARAMS = %i(session_store start_action api_token)

    def initialize
      @session_store = Rails.cache
      @logger = Rails.logger
      @client = TelegramWorkflow::Client
    end

    def verify!
      blank_params = REQUIRED_PARAMS.select { |p| send(p).nil? }

      if blank_params.any?
        raise TelegramWorkflow::Errors::MissingConfiguration, blank_params
      end
    end
  end
end
