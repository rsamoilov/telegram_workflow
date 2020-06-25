class Actions::ListAppointments < TelegramWorkflow::Action
  def initial
    on_redirect do
      appointments = session[:appointments].map do |app|
        "<b>#{app[:name]}</b> on #{app[:date].to_s}"
      end

      # refer to https://core.telegram.org/bots/api#sendmessage for the list of available parameters
      client.send_message text: appointments.join("\n"), parse_mode: "HTML"
      redirect_to Actions::ListActions
    end
  end
end
