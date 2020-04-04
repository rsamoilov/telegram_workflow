require "http"

module TelegramWorkflow
end

require "telegram_workflow/action"
require "telegram_workflow/client"
require "telegram_workflow/config"
require "telegram_workflow/errors"
require "telegram_workflow/params"
require "telegram_workflow/session"
require "telegram_workflow/version"
require "telegram_workflow/workflow"

TelegramWorkflow.__after_configuration do
  TelegramWorkflow::Client.new(nil).__setup_webhook
end
