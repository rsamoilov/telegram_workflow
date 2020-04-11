module TelegramWorkflow::Errors
  class DoubleRedirect < StandardError
    def initialize(msg = "Redirect was called multiple times in the step callback.")
      super
    end
  end

  class ApiError < StandardError
  end
end
