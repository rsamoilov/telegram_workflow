class TelegramWorkflow::Action
  extend ::Forwardable
  def_delegators :@__workflow, :client, :params, :logger, :redirect_to

  def initialize(workflow, session, flash)
    @__workflow = workflow
    @__session = session
    @__flash = flash
  end

  def shared
    :__continue
  end

  def on_redirect(&block)
    @on_redirect = block
  end

  def on_message(&block)
    @on_message = block
  end

  def __reset_callbacks
    @on_redirect = @on_message = nil
  end

  def __run_on_redirect
    @on_redirect.call if @on_redirect
  end

  def __run_on_message
    @on_message.call if @on_message
  end

  private

  def session
    @__session
  end

  def flash
    @__flash
  end
end
