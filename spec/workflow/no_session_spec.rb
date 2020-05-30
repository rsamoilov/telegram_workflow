require "support/workflow_context"

module NoSessionSpec
  class StartAction < TelegramWorkflow::Action
    def initial
      on_message { redirect_to NextAction }
    end
  end

  class NextAction < TelegramWorkflow::Action
    def initial
      on_redirect do
        verifier.set_session(session)
      end
    end
  end
end

RSpec.describe TelegramWorkflow::Workflow do
  include_context "set up workflow", start_action: NoSessionSpec::StartAction

  let!(:params) { {} }

  it "runs callbacks" do
    expect(verifier).to receive(:set_session) do |session|
      expect { session[:name] }.to raise_error(TelegramWorkflow::Errors::NoSession)
      expect { session[:name] = "test" }.to raise_error(TelegramWorkflow::Errors::NoSession)
    end

    workflow.process
  end
end
