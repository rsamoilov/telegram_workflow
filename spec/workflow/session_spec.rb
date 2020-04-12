require "support/workflow_context"

module SessionSpec
  class StartAction < TelegramWorkflow::Action
    def initial
      on_message do
        verifier.start_action__initial_step(session)
        session[:key1] = "value1"
        redirect_to :first_step
      end
    end

    def first_step
      on_redirect do
        verifier.start_action__first_step(session)
        session[:key2] = "value2"
        redirect_to :second_step
      end
    end

    def second_step
      on_redirect do
        verifier.start_action__second_step(session)
        redirect_to NextAction
      end
    end
  end

  class NextAction < TelegramWorkflow::Action
    def initial
      on_redirect do
        verifier.next_action__initial_step(session)
      end

      on_message do
        verifier.next_action__initial_step(session)
      end
    end
  end
end

RSpec.describe TelegramWorkflow::Workflow do
  include_context "set up workflow", start_action: SessionSpec::StartAction

  it "persists the session" do
    expect(verifier).to receive(:start_action__initial_step).with({}).once
    expect(verifier).to receive(:start_action__first_step).with({ key1: "value1" }).once
    expect(verifier).to receive(:start_action__second_step).with({ key1: "value1", key2: "value2" }).once
    expect(verifier).to receive(:next_action__initial_step).with({ key1: "value1", key2: "value2" }).twice
    subject.process

    params[:message][:text] = "new message"
    described_class.new(params).process
  end
end
