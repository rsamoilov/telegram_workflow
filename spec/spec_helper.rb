require "coveralls"
Coveralls.wear!

require "bundler/setup"
require "telegram_workflow"
require "active_support/all"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do |test|
    unless test.metadata[:type] == :telegram_action
      allow(TelegramWorkflow).to receive(:config).and_return(double(
        session_store: TelegramWorkflow::Stores::InMemory.new,
        logger: double(info: nil, error: nil),
        client: TelegramWorkflow::Client,
        start_action: nil,
        webhook_url: "https://test.webhook.url",
        api_token: "TEST_TOKEN_111"
      ))
    end
  end
end
