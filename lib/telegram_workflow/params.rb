class TelegramWorkflow::Params
  def initialize(params)
    @params = params
  end

  def [](key)
    @params[key]
  end

  def user
    @user ||= @params.dig(:message, :from) ||
      @params.dig(:callback_query, :from) ||
      @params.dig(:pre_checkout_query, :from) ||
      @params.dig(:shipping_query, :from) ||
      @params.dig(:inline_query, :from) ||
      @params.dig(:chosen_inline_result, :from)
  end

  def language_code
    user[:language_code]
  end

  def user_id
    user[:id]
  end

  def username
    user[:username]
  end

  def chat_id
    @params.dig(:message, :chat, :id) ||
      @params.dig(:callback_query, :message, :chat, :id) ||
      @params.dig(:edited_message, :chat, :id) ||
      @params.dig(:channel_post, :chat, :id) ||
      @params.dig(:edited_channel_post, :chat, :id)
  end

  def message_text
    @params.dig(:message, :text)
  end

  def callback_data
    @params.dig(:callback_query, :data)
  end

  def start?
    message_text == "/start".freeze
  end
end
