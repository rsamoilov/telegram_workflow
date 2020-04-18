require "support/workflow_context"

module DoubleRedirectSpec
  class StartAction < TelegramWorkflow::Action
    def initial
      on_message do
        redirect_to NextAction
        redirect_to :next_step
      end
    end

    def next_step
    end
  end

  class NextAction < TelegramWorkflow::Action
    def initial
    end
  end
end

RSpec.describe TelegramWorkflow::Workflow do
  include_context "set up workflow", start_action: DoubleRedirectSpec::StartAction

  it "raises an exception" do
    expect { workflow.process }.to raise_error(TelegramWorkflow::Errors::DoubleRedirect)
  end
end
