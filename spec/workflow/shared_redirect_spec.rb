require "support/workflow_context"

module SharedRedirectSpec
  class StartAction < TelegramWorkflow::Action
    def initial
      on_message { redirect_to :shared }
    end
  end
end

RSpec.describe TelegramWorkflow::Workflow do
  include_context "set up workflow", start_action: SharedRedirectSpec::StartAction

  it "doesn't allow to redirect to shared step" do
    expect { subject.process }.to raise_error(TelegramWorkflow::Errors::SharedRedirect)
  end
end
