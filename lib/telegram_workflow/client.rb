class TelegramWorkflow::Client
  AVAILABLE_ACTIONS = %i(
    getUpdates
    setWebhook
    deleteWebhook
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

  def initialize(chat_id)
    @chat_id = chat_id
    @webhook_url = TelegramWorkflow.config.webhook_url
    @api_url = "https://api.telegram.org/bot#{TelegramWorkflow.config.api_token}"
  end

  def __setup_webhook
    TelegramWorkflow.config.logger.info "[TelegramWorkflow] Checking webhook setup..."

    on_webhook_changed do
      TelegramWorkflow.config.logger.info "[TelegramWorkflow] Deleting an old webhook and setting up the new one..."
      delete_webhook
      set_webhook(url: @webhook_url)
    end
  end

  private

  def on_webhook_changed
    webhook_file_path = "tmp/telegram_workflow.webhook_url"
    current_webhook_url = File.read(webhook_file_path) if File.exists?(webhook_file_path)

    if current_webhook_url != @webhook_url
      yield
      File.write(webhook_file_path, @webhook_url)
    end
  end

  def make_request(action, params)
    response = ::HTTP.post("#{@api_url}/#{action}", json: { chat_id: @chat_id, **params })

    if response.code != 200
      raise TelegramWorkflow::Errors::ApiError, response.parse["description"]
    end
  end
end
