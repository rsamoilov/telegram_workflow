class TelegramWorkflow::Workflow
  attr_reader :params, :client

  def initialize(raw_params)
    @params  = TelegramWorkflow::Params.new(raw_params)
    @session = TelegramWorkflow::Session.new(@params)
    @client  = TelegramWorkflow.config.client.new(@params.chat_id)
  end

  def current_user
    return @current_user if @current_user
    @current_user = User.find(@session.read(:user_id)) if @session.read(:user_id)
  end

  def current_user=(user)
    @session.write(:user_id, user.id)
  end

  def process
    if @params.start?
      @session.clear
    end

    current_action.public_send(current_step) # setup callbacks
    current_action.__run_on_message # run a callback

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

      action_class.new(self, @session.action_session)
    end
  end

  def set_current_action(action_class)
    @session.write(:current_action, action_class.to_s)
    set_current_step(nil)
    @session.reset_action_session

    @current_action = action_class.new(self, @session.action_session)
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
      @session.action_session.merge!(session_params)
    end

    current_action.public_send(current_step) # setup callbacks
    current_action.__run_on_redirect # run a callback
  end
end
