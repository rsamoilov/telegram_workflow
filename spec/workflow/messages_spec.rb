require "support/workflow_context"

module MessagesSpec
  class StartAction < TelegramWorkflow::Action
    def initial
      on_message { redirect_to NextAction }
    end
  end

  class NextAction < TelegramWorkflow::Action
    def initial
      on_redirect do
        verifier.next_action__initial__on_redirect
      end

      on_message do
        verifier.next_action__initial__on_message
        redirect_to :next_step
      end
    end

    def next_step
      on_redirect do
        verifier.next_action__next_step__on_redirect
      end

      on_message do
        verifier.next_action__next_step__on_message
      end
    end
  end
end

RSpec.describe TelegramWorkflow::Workflow do
  include_context "set up workflow", start_action: MessagesSpec::StartAction

  it "runs callbacks" do
    expect(verifier).to receive(:next_action__initial__on_redirect).once
    workflow.process

    expect(verifier).to receive(:next_action__initial__on_message).once
    expect(verifier).to receive(:next_action__next_step__on_redirect).once
    params["message"]["text"] = "new message"
    workflow.process

    expect(verifier).to receive(:next_action__next_step__on_message).once
    params["message"]["text"] = "another message"
    workflow.process
  end
end
