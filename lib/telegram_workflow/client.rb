class TelegramWorkflow::Client
  API_VERSION = "4.9"
  WebhookFilePath = Pathname.new("tmp/telegram_workflow/webhook_url.txt")

  AVAILABLE_ACTIONS = %i(
    getUpdates
    getWebhookInfo

    getMe
    sendMessage
    forwardMessage
    sendPhoto
    sendAudio
    sendDocument
    sendVideo
    sendAnimation
    sendVoice
    sendVideoNote
    sendMediaGroup
    sendLocation
    editMessageLiveLocation
    stopMessageLiveLocation
    sendVenue
    sendContact
    sendPoll
    sendDice
    sendChatAction
    getUserProfilePhotos
    getFile
    kickChatMember
    unbanChatMember
    restrictChatMember
    promoteChatMember
    setChatAdministratorCustomTitle
    setChatPermissions
    exportChatInviteLink
    setChatPhoto
    deleteChatPhoto
    setChatTitle
    setChatDescription
    pinChatMessage
    unpinChatMessage
    leaveChat
    getChat
    getChatAdministrators
    getChatMembersCount
    getChatMember
    setChatStickerSet
    deleteChatStickerSet
    answerCallbackQuery
    setMyCommands
    getMyCommands

    editMessageText
    editMessageCaption
    editMessageMedia
    editMessageReplyMarkup
    stopPoll
    deleteMessage

    sendSticker
    getStickerSet
    uploadStickerFile
    createNewStickerSet
    addStickerToSet
    setStickerPositionInSet
    deleteStickerFromSet
    setStickerSetThumb

    answerInlineQuery

    sendInvoice
    answerShippingQuery
    answerPreCheckoutQuery

    setPassportDataErrors

    sendGame
    setGameScore
    getGameHighScores
  )

  AVAILABLE_ACTIONS.each do |action|
    method_name = action.to_s.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase

    define_method(method_name) do |params = {}|
      make_request(action, params)
    end
  end

  def initialize(chat_id = nil)
    @chat_id = chat_id
    @webhook_url = TelegramWorkflow.config.webhook_url
    @api_url = "https://api.telegram.org/bot#{TelegramWorkflow.config.api_token}"
  end

  def set_webhook(params = {})
    make_request("setWebhook", params)
    cached_webhook_url(new_url: @webhook_url)
  end

  def delete_webhook
    make_request("deleteWebhook", {})
    cached_webhook_url(new_url: "")
  end

  def __setup_webhook
    TelegramWorkflow.config.logger.info "[TelegramWorkflow] Checking webhook setup..."

    if cached_webhook_url != @webhook_url
      TelegramWorkflow.config.logger.info "[TelegramWorkflow] Setting up a new webhook..."
      set_webhook(url: @webhook_url)
    end
  end

  private

  def cached_webhook_url(new_url: nil)
    unless WebhookFilePath.exist?
      WebhookFilePath.dirname.mkpath
      WebhookFilePath.write("")
    end

    if new_url.nil?
      WebhookFilePath.read
    else
      WebhookFilePath.write(new_url)
    end
  end

  def make_request(action, params)
    has_file_params = params.any? { |_, param| param.is_a?(TelegramWorkflow::InputFile) }
    request_type = has_file_params ? :form : :json

    response = ::Retryable.retryable(tries: 3, on: HTTP::ConnectionError) do
      ::HTTP.post("#{@api_url}/#{action}", request_type => { chat_id: @chat_id, **params })
    end

    if response.code != 200
      raise TelegramWorkflow::Errors::ApiError, response.parse["description"]
    end

    response.parse
  end
end
