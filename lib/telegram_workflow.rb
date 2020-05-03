require "http"

module TelegramWorkflow
  def self.process(params)
    Workflow.new(params).process
  end

  def self.updates(offset: nil, limit: nil, timeout: 60, allowed_updates: nil)
    params = {}
    params[:offset] = offset if offset
    params[:limit] = limit if limit
    params[:timeout] = timeout if timeout
    params[:allowed_updates] = allowed_updates if allowed_updates

    Updates.new(params).enum
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

TelegramWorkflow.__after_configuration do
  TelegramWorkflow::Client.new.__setup_webhook
end
