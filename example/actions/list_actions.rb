class Actions::ListActions < TelegramWorkflow::Action
  def initial
    on_redirect do
      available_actions = [
        [{ text: "Make an appointment", callback_data: "create" }]
      ]

      if session[:appointments]&.any?
        available_actions.unshift [{ text: "List my appointments", callback_data: "list" }]
      end

      # this is the customized client object
      client.send_actions "Select an action:", available_actions
    end

    # `params.callback_data` here will be one of the identifiers defined as `callback_data` in `available_actions` array
    # refer to https://core.telegram.org/bots/api#inlinekeyboardbutton
    on_message do
      next_action = if params.callback_data == "create"
        Actions::SelectDoctor
      elsif params.callback_data == "list"
        Actions::ListAppointments
      end

      redirect_to next_action
    end
  end
end
