class TelegramWorkflow::Client
  API_VERSION = "6.7"
  WebhookConfigPath = Pathname.new("tmp/telegram_workflow/webhook_config.txt")

  AVAILABLE_ACTIONS = %i(
    getUpdates
    getWebhookInfo

    getMe
    sendMessage
    forwardMessage
    copyMessage
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
    banChatMember
    unbanChatMember
    restrictChatMember
    promoteChatMember
    setChatAdministratorCustomTitle
    banChatSenderChat
    unbanChatSenderChat
    setChatPermissions
    exportChatInviteLink
    createChatInviteLink
    editChatInviteLink
    revokeChatInviteLink
    setChatPhoto
    deleteChatPhoto
    setChatTitle
    setChatDescription
    setMyDescription
    getMyDescription
    setMyShortDescription
    getMyShortDescription
    pinChatMessage
    unpinChatMessage
    unpinAllChatMessages
    leaveChat
    getChat
    getChatAdministrators
    getChatMembersCount
    getChatMemberCount
    getChatMember
    setChatStickerSet
    deleteChatStickerSet
    answerCallbackQuery
    answerWebAppQuery
    setMyCommands
    deleteMyCommands
    getMyCommands
    setChatMenuButton
    getChatMenuButton 
    setMyDefaultAdministratorRights
    getMyDefaultAdministratorRights
    getCustomEmojiStickers

    createForumTopic
    editForumTopic
    closeForumTopic
    reopenForumTopic
    deleteForumTopic
    unpinAllForumTopicMessages
    getForumTopicIconStickers
    editGeneralForumTopic
    closeGeneralForumTopic
    reopenGeneralForumTopic
    hideGeneralForumTopic
    unhideGeneralForumTopic

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
    setStickerSetThumbnail

    answerInlineQuery

    sendInvoice
    answerShippingQuery
    answerPreCheckoutQuery

    setPassportDataErrors

    sendGame
    setGameScore
    getGameHighScores

    logOut
    close
  )

  DEPRECATED_ACTIONS = {
    kickChatMember: :banChatMember,
    getChatMembersCount: :getChatMemberCount
  }

  AVAILABLE_ACTIONS.each do |action|
    method_name = action.to_s.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase

    define_method(method_name) do |params = {}|
      if deprecated_in_favor_of = DEPRECATED_ACTIONS[action]
        TelegramWorkflow.config.logger.warn "[TelegramWorkflow] #{action} action is deprecated. Use #{deprecated_in_favor_of} action instead."
      end

      @inline ?
        save_request(action, params) :
        make_request(action, params)
    end
  end

  attr_accessor :inline, :inline_request
  attr_reader :api_url

  def initialize(chat_id = nil)
    @chat_id = chat_id
    @api_url = "https://api.telegram.org/bot#{TelegramWorkflow.config.api_token}"
  end

  def set_webhook(params = {})
    make_request("setWebhook", params)
    cached_webhook_config(params)
  end

  def delete_webhook(params = {})
    make_request("deleteWebhook", params)
    cached_webhook_config(params)
  end

  def __setup_webhook(webhook_url = TelegramWorkflow.config.webhook_url, params = {})
    TelegramWorkflow.config.logger.info "[TelegramWorkflow] Checking webhook setup..."

    webhook_params = { url: webhook_url, allowed_updates: [], **params }

    if cached_webhook_config != webhook_params
      TelegramWorkflow.config.logger.info "[TelegramWorkflow] Setting up a new webhook..."
      set_webhook(webhook_params)
    end
  end

  private

  def cached_webhook_config(new_config = nil)
    unless WebhookConfigPath.exist?
      WebhookConfigPath.dirname.mkpath
      WebhookConfigPath.write(Marshal.dump({}))
    end

    if new_config.nil?
      Marshal.load(WebhookConfigPath.read)
    else
      WebhookConfigPath.write(Marshal.dump(new_config))
    end
  end

  def save_request(action, params = {})
    raise TelegramWorkflow::Errors::DoubleInlineRequest if @inline_request
    @inline_request = { method: action, chat_id: @chat_id, **params }
  end

  def make_request(action, params = {})
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
