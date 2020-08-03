require "support/workflow_context"

module InlineClientDoubleRequestSpec
  class StartAction < TelegramWorkflow::Action
    def initial
      client.inline = true

      on_message do
        client.forward_message from_chat_id: 123456, message_id: 7890
        client.send_message text: "Hello world!"
      end
    end
  end
end

RSpec.describe TelegramWorkflow::Workflow do
  include_context "set up workflow", start_action: InlineClientDoubleRequestSpec::StartAction

  it "raises an exception on second inline request" do
    expect(HTTP).not_to receive(:post)
    expect { workflow.process }.to raise_error(TelegramWorkflow::Errors::DoubleInlineRequest)
  end
end
