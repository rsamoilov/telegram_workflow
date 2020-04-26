require "support/workflow_context"

module SharedStepSpec
  class BaseAction < TelegramWorkflow::Action
    def shared
      if params.message_text == "cancel"
        verifier.shared__cancel
      elsif params.message_text == "redirect"
        redirect_to NextAction
      else
        super
      end
    end
  end

  class StartAction < BaseAction
    def initial
      on_message do
        verifier.start_action__initial__on_message
      end
    end
  end

  class NextAction < BaseAction
    def initial
      on_redirect do
        verifier.next_action__initial__on_redirect
      end
    end
  end
end

RSpec.describe TelegramWorkflow::Workflow do
  include_context "set up workflow", start_action: SharedStepSpec::StartAction

  it "runs shared steps" do
    expect(verifier).to receive(:start_action__initial__on_message).once
    workflow.process

    params["message"]["text"] = "cancel"
    expect(verifier).to receive(:shared__cancel).once
    expect(verifier).not_to receive(:start_action__initial__on_message)
    workflow.process

    params["message"]["text"] = "redirect"
    expect(verifier).to receive(:next_action__initial__on_redirect).once
    expect(verifier).not_to receive(:start_action__initial__on_message)
    workflow.process

    # next request should continue processing from NextAction
    expect(verifier).to receive(:next_action__initial__on_redirect).once
    expect(verifier).not_to receive(:start_action__initial__on_message)
    workflow.process
  end
end
