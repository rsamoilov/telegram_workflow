unless defined?(Rails)
  require "logger"
end

module TelegramWorkflow
  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield(config)
      config.verify!

      @__after_configuration.call(config)
    end

    def __after_configuration(&block)
      @__after_configuration = block
    end
  end

  class Configuration
    attr_accessor :session_store, :logger, :client, :start_action, :webhook_url, :api_token,
                  :webhook_params

    REQUIRED_PARAMS = %i(session_store start_action api_token)

    def initialize
      @client = TelegramWorkflow::Client
      @webhook_params = {}

      if defined?(Rails)
        @session_store = Rails.cache
        @logger = Rails.logger
      else
        @session_store = TelegramWorkflow::Stores::InMemory.new
        @logger = Logger.new(STDOUT)
      end
    end

    def verify!
      blank_params = REQUIRED_PARAMS.select { |p| send(p).nil? }

      if blank_params.any?
        raise TelegramWorkflow::Errors::MissingConfiguration, blank_params
      end
    end
  end
end
