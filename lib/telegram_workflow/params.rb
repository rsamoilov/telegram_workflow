# frozen_string_literal: true

class TelegramWorkflow::Params
  def initialize(params)
    @params = params
  end

  def [](key)
    @params[key]
  end

  def user
    @user ||= message&.dig("from") ||
      @params.dig("callback_query", "from") ||
      @params.dig("pre_checkout_query", "from") ||
      @params.dig("shipping_query", "from") ||
      @params.dig("inline_query", "from") ||
      @params.dig("chosen_inline_result", "from") ||
      @params.dig("poll_answer", "user")
  end

  def language_code
    user&.dig("language_code") || "en"
  end

  def user_id
    user&.dig("id")
  end

  def username
    user&.dig("username")
  end

  def chat_id
    @params.dig("message", "chat", "id") ||
      @params.dig("callback_query", "message", "chat", "id") ||
      @params.dig("edited_message", "chat", "id") ||
      @params.dig("channel_post", "chat", "id") ||
      @params.dig("edited_channel_post", "chat", "id")
  end

  def message
    @params["message"] ||
      @params["edited_message"] ||
      @params["channel_post"] ||
      @params["edited_channel_post"]
  end

  def message_text
    message&.dig("text")
  end

  def callback_data
    @params.dig("callback_query", "data")
  end

  def inline_data
    @params.dig("inline_query", "query")
  end

  def start?
    !!message_text&.start_with?("/start")
  end

  def command?
    !!message_text&.start_with?("/")
  end

  def deep_link_payload
    match = /\A\/(startgroup|start) (?<payload>.+)\z/.match(message_text)
    match["payload"] if match
  end

  def to_h
    @params
  end
end
