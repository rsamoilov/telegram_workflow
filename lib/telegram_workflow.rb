require "http"
require "retryable"

module TelegramWorkflow
  module Stores
  end

  def self.process(params)
    Workflow.new(params).process
  end

  def self.updates(offset: nil, limit: nil, timeout: 60, allowed_updates: nil)
    params = {}
    params[:offset] = offset if offset
    params[:limit] = limit if limit
    params[:timeout] = timeout if timeout
    params[:allowed_updates] = allowed_updates if allowed_updates

    (@updates = Updates.new(params)).enum
  end

  def self.stop_updates
    @updates && @updates.stop = true
  end
end

require "telegram_workflow/action"
require "telegram_workflow/client"
require "telegram_workflow/config"
require "telegram_workflow/errors"
require "telegram_workflow/params"
require "telegram_workflow/session"
require "telegram_workflow/version"
require "telegram_workflow/updates"
require "telegram_workflow/workflow"
require "telegram_workflow/input_file"
require "telegram_workflow/stores/in_memory"
require "telegram_workflow/stores/file"

TelegramWorkflow.__after_configuration do |config|
  if config.webhook_url
    TelegramWorkflow::Client.new.__setup_webhook
  end
end
