require "support/workflow_context"

module ActionRedirectSpec
  class StartAction < TelegramWorkflow::Action
    def initial
      on_message do
        verifier.start_action__initial__on_message
        redirect_to NextAction
      end
    end
  end

  class NextAction < TelegramWorkflow::Action
    def initial
      on_redirect { verifier.next_action__initial__on_redirect }
      on_message { verifier.next_action__initial__on_message }
    end
  end
end

RSpec.describe TelegramWorkflow::Workflow do
  include_context "set up workflow", start_action: ActionRedirectSpec::StartAction

  it "runs callbacks" do
    expect(verifier).to receive(:start_action__initial__on_message).once
    expect(verifier).to receive(:next_action__initial__on_redirect).once
    expect(verifier).not_to receive(:next_action__initial__on_message)
    workflow.process
  end
end
