class Actions::Start < TelegramWorkflow::Action
  def initial
    # we don't need to store current user id in session or make any other setup,
    # so just redirect to the `ListActions` action
    on_message do
      redirect_to Actions::ListActions
    end
  end
end
