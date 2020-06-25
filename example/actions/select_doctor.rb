class Actions::SelectDoctor < TelegramWorkflow::Action
  def initial
    on_redirect do
      available_doctors = [
        [{ text: "Family Medicine", callback_data: "family" }],
        [{ text: "Emergency Medicine", callback_data: "emergency" }],
        [{ text: "Pediatrics", callback_data: "pediatrics" }]
      ]

      client.send_actions "Select a doctor:", available_doctors
    end

    on_message do
      # pass `specialty` parameter to the next action
      # https://github.com/rsamoilov/telegram_workflow#redirect_toaction_or_class-flash_params--
      redirect_to Actions::CreateAppointment, specialty: params.callback_data
    end
  end
end
