require "support/workflow_context"

module MultipleStepsRedirectSpec
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
        redirect_to :second_step
      end
    end

    def second_step
      on_redirect do
        verifier.start_action__second_step__on_redirect
        redirect_to NextAction
      end
    end
  end

  class NextAction < TelegramWorkflow::Action
    def initial
      on_redirect do
        verifier.next_action__initial_step__on_redirect
        redirect_to :first_step
      end
    end

    def first_step
      on_redirect do
        verifier.next_action__first_step__on_redirect
      end
    end
  end
end

RSpec.describe TelegramWorkflow::Workflow do
  include_context "set up workflow", start_action: MultipleStepsRedirectSpec::StartAction

  it "runs callbacks" do
    expect(verifier).to receive(:start_action__initial__on_message).once
    expect(verifier).to receive(:start_action__first_step__on_redirect).once
    expect(verifier).to receive(:start_action__second_step__on_redirect).once
    expect(verifier).to receive(:next_action__initial_step__on_redirect).once
    expect(verifier).to receive(:next_action__first_step__on_redirect).once
    subject.process
  end
end
