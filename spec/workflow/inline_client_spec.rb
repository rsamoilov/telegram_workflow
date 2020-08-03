require "support/workflow_context"

module InlineClientSpec
  class StartAction < TelegramWorkflow::Action
    def initial
      client.inline = true

      on_message do
        client.forward_message from_chat_id: 123456, message_id: 7890
      end
    end
  end
end

RSpec.describe TelegramWorkflow::Workflow do
  include_context "set up workflow", start_action: InlineClientSpec::StartAction

  it "correctly returns an inline request" do
    expect(HTTP).not_to receive(:post)

    result = workflow.process
    expect(result).to include(method: :forwardMessage, from_chat_id: 123456, message_id: 7890, chat_id: chat_id)
  end
end
