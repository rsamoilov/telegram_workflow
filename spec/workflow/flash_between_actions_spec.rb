require "support/workflow_context"

module FlashBetweenActionsSpec
  class StartAction < TelegramWorkflow::Action
    def initial
      on_message do
        redirect_to :first_step, key1: "value1"
      end
    end

    def first_step
      on_redirect do
        verifier.start_action__first_step(flash)
        redirect_to FirstAction, key2: "value2"
      end
    end
  end

  class FirstAction < TelegramWorkflow::Action
    def initial
      on_redirect do
        verifier.first_action__initial_step(flash)
        redirect_to SecondAction, key2: "value333"
      end
    end
  end

  class SecondAction < TelegramWorkflow::Action
    def initial
      on_redirect do
        verifier.second_action__initial_step(flash)
      end
    end
  end
end

RSpec.describe TelegramWorkflow::Workflow do
  include_context "set up workflow", start_action: FlashBetweenActionsSpec::StartAction

  it "preserves the flash between different actions" do
    expect(verifier).to receive(:start_action__first_step).with({ key1: "value1" })
    expect(verifier).to receive(:first_action__initial_step).with({ key2: "value2" })
    expect(verifier).to receive(:second_action__initial_step).with({ key2: "value333" })
    subject.process
  end
end
