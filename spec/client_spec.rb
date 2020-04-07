RSpec.describe TelegramWorkflow::Client do
  let!(:chat_id) { 123456777 }

  subject { described_class.new(chat_id) }

  it "implements telegram API methods" do
    described_class::AVAILABLE_ACTIONS.each do |action_name|
      method_name = ActiveSupport::Inflector.underscore(action_name)
      expect(subject).to respond_to(method_name)
    end
  end

  it "correctly sends requests without params" do
    expect(HTTP).to receive(:post).
      with(/^.+\/leaveChat$/, { json: { chat_id: chat_id } }).
      and_return(double(parse: nil))

    subject.leave_chat
  end

  it "correctly sends requests with params" do
    invoice_params = {
      description: "test invoice description",
      payload: "test payload",
      amount: "100"
    }

    expect(HTTP).to receive(:post).
      with(/^.+\/sendInvoice$/, { json: invoice_params.merge(chat_id: chat_id) }).
      and_return(double(parse: nil))

    subject.send_invoice(invoice_params)
  end
end
