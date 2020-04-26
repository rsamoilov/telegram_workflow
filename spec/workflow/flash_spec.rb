require "support/workflow_context"

module FlashSpec
  class StartAction < TelegramWorkflow::Action
    def initial
      on_message do
        verifier.start_action__initial_step(flash)
        flash[:key1] = "value1"
        redirect_to :first_step
      end
    end

    def first_step
      on_redirect do
        verifier.start_action__first_step(flash)
        redirect_to :second_step, key2: "value2"
      end
    end

    def second_step
      on_redirect do
        verifier.start_action__second_step(flash)
        redirect_to NextAction
      end
    end
  end

  class NextAction < TelegramWorkflow::Action
    def initial
      on_redirect do
        verifier.next_action__initial_step(flash)
      end

      on_message do
        flash[:key3] = "value3"
        verifier.next_action__initial_step__on_message(flash)
      end
    end
  end
end

RSpec.describe TelegramWorkflow::Workflow do
  include_context "set up workflow", start_action: FlashSpec::StartAction

  it "resets the flash when redirecting to another action" do
    expect(verifier).to receive(:start_action__initial_step).with({}).once
    expect(verifier).to receive(:start_action__first_step).with({ key1: "value1" }).once
    expect(verifier).to receive(:start_action__second_step).with({ key1: "value1", key2: "value2" }).once
    expect(verifier).to receive(:next_action__initial_step).with({}).once
    workflow.process
  end

  it "persists the flash across the requests" do
    allow(verifier).to receive(:start_action__initial_step)
    allow(verifier).to receive(:start_action__first_step)
    allow(verifier).to receive(:start_action__second_step)
    allow(verifier).to receive(:next_action__initial_step)
    workflow.process

    params["message"]["text"] = "new message"
    expect(verifier).to receive(:next_action__initial_step__on_message).with({ key3: "value3" }).twice
    2.times { workflow.process }
  end
end
