require "support/workflow_context"

module StartSesssionSpec
  class StartAction < TelegramWorkflow::Action
    def initial
      on_message do
        verifier.initial_action__on_message(session)
        redirect_to NextAction
      end
    end
  end

  class NextAction < TelegramWorkflow::Action
    def initial
      on_redirect do
        session[:key] = "next_action_value"
        verifier.next_action__on_message(session)
      end
    end
  end
end

RSpec.describe TelegramWorkflow::Workflow do
  include_context "set up workflow", start_action: StartSesssionSpec::StartAction

  it "doesn't clear the whole session when receiving /start message" do
    expect(verifier).to receive(:initial_action__on_message).with({}).once
    expect(verifier).to receive(:next_action__on_message).with({ key: "next_action_value" }).once
    workflow.process

    # send /start command again; session value should still be there
    expect(verifier).to receive(:initial_action__on_message).with({ key: "next_action_value" }).once
    expect(verifier).to receive(:next_action__on_message).with({ key: "next_action_value" }).once
    workflow.process
  end
end
