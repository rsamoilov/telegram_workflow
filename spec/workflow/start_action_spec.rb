require "support/workflow_context"

module StartActionSpec
  class StartAction < TelegramWorkflow::Action
    def initial
      on_redirect { verifier.start_action__initial__on_redirect }
      on_message { verifier.start_action__initial__on_message }
    end
  end
end

RSpec.describe TelegramWorkflow::Workflow do
  include_context "set up workflow", start_action: StartActionSpec::StartAction

  it "runs callbacks" do
    expect(verifier).to receive(:start_action__initial__on_message).once
    expect(verifier).not_to receive(:start_action__initial__on_redirect)
    workflow.process
  end
end
