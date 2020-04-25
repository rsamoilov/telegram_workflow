module TelegramWorkflow::Errors
  class DoubleRedirect < StandardError
    def initialize(msg = "Redirect was called multiple times in the step callback.")
      super
    end
  end

  class SharedRedirect < StandardError
    def initialize(msg = "You cannot redirect to a shared step.")
      super
    end
  end

  class ApiError < StandardError
  end

  class MissingConfiguration < StandardError
    def initialize(missing_config_params)
      msg = "Missing required configuration params: #{missing_config_params.join(", ")}"
      super(msg)
    end
  end
end
