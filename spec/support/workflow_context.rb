RSpec.shared_context "set up workflow", shared_context: :metadata do |args|
  start_action = args.fetch(:start_action)

  let!(:verifier) { double }

  before do
    allow_any_instance_of(TelegramWorkflow::Action).to receive(:verifier).and_return(verifier)
    allow(TelegramWorkflow.config).to receive(:start_action).and_return(start_action)
  end

  let!(:chat_id) { 1111111 }
  let!(:user_id) { 2222222 }
  let!(:params) do
    {
      message: {
        text: "/start",
        chat: { id: chat_id },
        from: { id: user_id }
      }
    }
  end

  subject { described_class.new(params) }
end
