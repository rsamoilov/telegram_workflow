class TelegramWorkflow::Workflow
  attr_reader :params, :client

  def initialize(raw_params)
    @params  = TelegramWorkflow::Params.new(raw_params)
    @session = TelegramWorkflow::Session.new(@params)

    if @params.start?
      @session.clear
    end

    chat_id = @session.read(:chat_id) || @session.write(:chat_id, @params.chat_id)
    @client = TelegramWorkflow.config.client.new(chat_id)
  end

  def process
    # run the shared step
    shared_step_result = current_action.shared

    if shared_step_result == :__continue
      current_action.public_send(current_step) # setup callbacks
      current_action.__run_on_message # run a callback
    end

    while @redirect_to
      do_redirect
    end

    @session.dump
  end

  def redirect_to(action_or_step, session_params = nil)
    if @redirect_to
      raise TelegramWorkflow::Errors::DoubleRedirect
    end

    @redirect_to = action_or_step
    @session_params = session_params
  end

  private

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
