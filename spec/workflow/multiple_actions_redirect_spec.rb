require "support/workflow_context"

module MultipleActionsRedirectSpec
  class StartAction < TelegramWorkflow::Action
    def initial
      on_message do
        verifier.start_action__initial__on_message
        redirect_to FirstAction
      end
    end
  end

  class FirstAction < TelegramWorkflow::Action
    def initial
      on_redirect do
        verifier.first_action__initial__on_redirect
        redirect_to SecondAction
      end
    end
  end

  class SecondAction < TelegramWorkflow::Action
    def initial
      on_redirect do
        verifier.second_action__initial__on_redirect
      end
    end
  end
end

RSpec.describe TelegramWorkflow::Workflow do
  include_context "set up workflow", start_action: MultipleActionsRedirectSpec::StartAction

  it "runs callbacks" do
    expect(verifier).to receive(:start_action__initial__on_message).once
    expect(verifier).to receive(:first_action__initial__on_redirect).once
    expect(verifier).to receive(:second_action__initial__on_redirect).once
    workflow.process
  end
end
