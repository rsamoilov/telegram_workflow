require "support/workflow_context"

module GlobalObjectsSpec
  class StartAction < TelegramWorkflow::Action
    def initial
      on_message do
        verifier.call_client(client)
        verifier.call_params(params)
        verifier.call_session(session)
        verifier.call_flash(flash)
      end
    end
  end

  class CustomClient < TelegramWorkflow::Client
  end
end

RSpec.describe TelegramWorkflow::Workflow do
  include_context "set up workflow", start_action: GlobalObjectsSpec::StartAction

  it "has access to all global objects" do
    expect(verifier).to receive(:call_client).with(instance_of(TelegramWorkflow::Client)).once
    expect(verifier).to receive(:call_params).with(instance_of(TelegramWorkflow::Params)).once
    expect(verifier).to receive(:call_session).with(instance_of(Hash)).once
    expect(verifier).to receive(:call_flash).with(instance_of(Hash)).once
    workflow.process
  end

  context "when configured" do
    before do
      expect(GlobalObjectsSpec::CustomClient).to receive(:new).with(chat_id).once.and_call_original
      allow(TelegramWorkflow.config).to receive(:client).and_return(GlobalObjectsSpec::CustomClient)
    end

    it "has access to configured global objects" do
      expect(verifier).to receive(:call_client).with(instance_of(GlobalObjectsSpec::CustomClient)).once
      expect(verifier).to receive(:call_params).with(instance_of(TelegramWorkflow::Params)).once
      expect(verifier).to receive(:call_session).with(instance_of(Hash)).once
      expect(verifier).to receive(:call_flash).with(instance_of(Hash)).once
      workflow.process
    end
  end
end
