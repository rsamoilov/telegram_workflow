require "support/workflow_context"

module GlobalObjectsSpec
  class StartAction < TelegramWorkflow::Action
    def initial
      on_message do
        verifier.call_client(client)
        verifier.call_params(params)
        verifier.call_session(session)
      end
    end
  end
end

RSpec.describe TelegramWorkflow::Workflow do
  include_context "set up workflow", start_action: GlobalObjectsSpec::StartAction

  it "has access to all global objects" do
    expect(verifier).to receive(:call_client).with(instance_of(TelegramWorkflow::Client)).once
    expect(verifier).to receive(:call_params).with(instance_of(TelegramWorkflow::Params)).once
    expect(verifier).to receive(:call_session).with(instance_of(Hash)).once
    subject.process
  end

  context "when configured" do
    let!(:custom_client) { "this is a test client object" }

    before do
      client_double = double
      expect(client_double).to receive(:new).with(chat_id).once.and_return(custom_client)

      allow(TelegramWorkflow.config).to receive(:client).and_return(client_double)
    end

    it "has access to configured global objects" do
      expect(verifier).to receive(:call_client).with(custom_client).once
      expect(verifier).to receive(:call_params).with(instance_of(TelegramWorkflow::Params)).once
      expect(verifier).to receive(:call_session).with(instance_of(Hash)).once
      subject.process
    end
  end
end
