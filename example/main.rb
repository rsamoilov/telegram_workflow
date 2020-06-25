require_relative "environment"

TelegramWorkflow.configure do |config|
  config.start_action = Actions::Start
  config.client = Client
  config.session_store = TelegramWorkflow::Stores::File.new
  config.api_token = <YOUR_TOKEN>
end

trap "SIGINT" do
  puts "Exiting..."
  TelegramWorkflow.stop_updates
end

TelegramWorkflow.updates(timeout: 5).each do |params|
  TelegramWorkflow.process(params)
end
