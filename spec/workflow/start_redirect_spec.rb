require "support/workflow_context"

module StartRedirectSpec
  class StartAction < TelegramWorkflow::Action
    def initial
      on_message { redirect_to NextAction }
    end
  end

  class NextAction < TelegramWorkflow::Action
    def initial
      on_redirect { redirect_to StartAction }
    end
  end
end

RSpec.describe TelegramWorkflow::Workflow do
  include_context "set up workflow", start_action: StartRedirectSpec::StartAction

  it "doesn't allow to redirect to a start action" do
    expect { workflow.process }.to raise_error(TelegramWorkflow::Errors::StartRedirect)
  end
end
