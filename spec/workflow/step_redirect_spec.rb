require "support/workflow_context"

module StepRedirectSpec
  class StartAction < TelegramWorkflow::Action
    def initial
      on_message do
        verifier.start_action__initial__on_message
        redirect_to :first_step
      end
    end

    def first_step
      on_redirect do
        verifier.start_action__first_step__on_redirect
      end

      on_message do
        verifier.start_action__first_step__on_message
      end
    end
  end
end

RSpec.describe TelegramWorkflow::Workflow do
  include_context "set up workflow", start_action: StepRedirectSpec::StartAction

  it "runs callbacks" do
    expect(verifier).to receive(:start_action__initial__on_message).once
    expect(verifier).to receive(:start_action__first_step__on_redirect).once
    expect(verifier).not_to receive(:start_action__first_step__on_message)
    workflow.process
  end
end
