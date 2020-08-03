require "support/workflow_context"

module ClientSpec
  class StartAction < TelegramWorkflow::Action
    def initial
      on_message { redirect_to :first_step }
    end

    def first_step
    end
  end
end

RSpec.describe TelegramWorkflow::Workflow do
  include_context "set up workflow", start_action: ClientSpec::StartAction

  it "stores chat id in session" do
    expect(TelegramWorkflow::Client).to receive(:new).with(chat_id).twice.and_call_original

    workflow.process

    params["message"].delete("chat")
    params["message"]["text"] = "test_message"
    workflow.process
  end
end
