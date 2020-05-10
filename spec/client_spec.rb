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
      and_return(double(code: 200, parse: nil))

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
      and_return(double(code: 200, parse: nil))

    subject.send_invoice(invoice_params)
  end

  it "raises an exception" do
    error_message = "there is no animation in the request"

    expect(HTTP).to receive(:post).and_return(double(
      code: 400,
      parse: { "description" => error_message }
    ))

    expect { subject.send_animation }.to raise_error(TelegramWorkflow::Errors::ApiError, error_message)
  end

  context "with webhook url caching" do
    subject { described_class.new }

    after do
      FileUtils.remove_dir "tmp", true
    end

    it "correctly sets the url" do
      url = "https://test.telegram.webhook.url"
      expect(HTTP).to receive(:post).with(/^.+\/setWebhook$/, { json: hash_including(url: url) }).
        and_return(double(code: 200, parse: nil))

      expect { subject.set_webhook(url: url) }.to change { described_class::WebhookFilePath.exist? }.to(true)
    end

    it "correctly deletes the url" do
      expect(HTTP).to receive(:post).with(/^.+\/deleteWebhook$/, kind_of(Hash)).
        and_return(double(code: 200, parse: nil))

      subject.delete_webhook
      expect(described_class::WebhookFilePath.read).to eq("")
    end

    it "correctly caches the url" do
      expect(HTTP).to receive(:post).
        with(/^.+\/setWebhook$/, { json: hash_including(url: TelegramWorkflow.config.webhook_url) }).
        once.
        and_return(double(code: 200, parse: nil))

      2.times { subject.__setup_webhook }
    end

    it "correctly changes the url" do
      expect(HTTP).to receive(:post).
        with(/^.+\/setWebhook$/, { json: hash_including(url: TelegramWorkflow.config.webhook_url) }).
        once.
        and_return(double(code: 200, parse: nil))
      subject.__setup_webhook

      new_url = "https://new.test.telegram.webhook.url"
      allow(TelegramWorkflow.config).to receive(:webhook_url).and_return(new_url)

      expect(HTTP).to receive(:post).
        with(/^.+\/setWebhook$/, { json: hash_including(url: new_url) }).
        once.
        and_return(double(code: 200, parse: nil))
      described_class.new.__setup_webhook
    end
  end
end
