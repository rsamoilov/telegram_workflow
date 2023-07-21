require "securerandom"

class TelegramWorkflow::Workflow
  attr_reader :params, :client, :logger

  def initialize(raw_params)
    @params  = TelegramWorkflow::Params.new(raw_params)
    @session = TelegramWorkflow::Session.new(@params)

    @logger = TelegramWorkflow.config.logger
    @logger = @logger.tagged(SecureRandom.hex(8)) if TelegramWorkflow.config.tagged_logger?

    if @params.start?
      set_current_action(TelegramWorkflow.config.start_action)
    end

    chat_id = @session.read(:chat_id) || @session.write(:chat_id, @params.chat_id)
    @client = TelegramWorkflow.config.client.new(chat_id)
  end

  def process
    # run the shared step
    shared_step_result = current_action.shared

    if shared_step_result == :__continue
      log_request
      current_action.public_send(current_step) # setup callbacks
      current_action.__run_on_message # run a callback
    else
      @logger.info "Processing by shared handler"
    end

    while @redirect_to
      do_redirect
    end

    @session.dump

    @client.inline_request
  end

  def redirect_to(action_or_step, session_params = nil)
    raise TelegramWorkflow::Errors::DoubleRedirect if @redirect_to
    raise TelegramWorkflow::Errors::SharedRedirect if action_or_step == :shared
    raise TelegramWorkflow::Errors::StartRedirect  if action_or_step == TelegramWorkflow.config.start_action

    @redirect_to = action_or_step
    @session_params = session_params
  end

  private

  def log_request
    @logger.info "Processing by #{current_action.class.name}##{current_step}"

    if TelegramWorkflow.config.webhook_url.nil?
      @logger.info "Parameters: #{@params.to_h}"
    end
  end

  def current_action
    @current_action ||= begin
      action_class = if action = @session.read(:current_action)
        Object.const_get(action)
      else
        TelegramWorkflow.config.start_action
      end

      action_class.new(self, @session.user_session, @session.flash)
    end
  end

  def set_current_action(action_class)
    @session.write(:current_action, action_class.to_s)
    set_current_step(nil)
    @session.reset_flash

    @current_action = action_class.new(self, @session.user_session, @session.flash)
  end

  def current_step
    @session.read(:current_step) || :initial
  end

  def set_current_step(step)
    @session.write(:current_step, step)
  end

  def do_redirect
    action_or_step = @redirect_to
    session_params = @session_params
    @redirect_to = @session_params = nil

    # reset on_message and on_redirect callbacks
    current_action.__reset_callbacks

    if action_or_step.is_a?(Class)
      set_current_action(action_or_step)
    else
      set_current_step(action_or_step)
    end

    if session_params
      @session.flash.merge!(session_params)
    end

    current_action.public_send(current_step) # setup callbacks
    current_action.__run_on_redirect # run a callback
  end
end
