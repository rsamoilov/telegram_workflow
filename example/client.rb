class Client < TelegramWorkflow::Client
  def send_actions(message, actions)
    send_message text: message, reply_markup: { inline_keyboard: actions }
  end
end
