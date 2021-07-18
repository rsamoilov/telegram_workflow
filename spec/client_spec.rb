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
      and_return(double(code: 200, parse: "leave_chat_response"))

    expect(subject.leave_chat).to eq("leave_chat_response")
  end

  it "correctly sends requests with params" do
    invoice_params = {
      description: "test invoice description",
      payload: "test payload",
      amount: "100"
    }

    expect(HTTP).to receive(:post).
      with(/^.+\/sendInvoice$/, { json: invoice_params.merge(chat_id: chat_id) }).
      and_return(double(code: 200, parse: "send_invoice_response"))

    expect(subject.send_invoice(invoice_params)).to eq("send_invoice_response")
  end

  it "raises an exception" do
    error_message = "there is no animation in the request"

    expect(HTTP).to receive(:post).and_return(double(
      code: 400,
      parse: { "description" => error_message }
    ))

    expect { subject.send_animation }.to raise_error(TelegramWorkflow::Errors::ApiError, error_message)
  end

  it "retries on HTTP errors" do
    expect(HTTP).to receive(:post).and_raise(HTTP::ConnectionError).twice
    expect(HTTP).to receive(:post).and_return(double(code: 200, parse: "parsed_response")).once

    expect(subject.send_message).to eq("parsed_response")
  end

  context "when uploading a file" do
    let!(:file) { File.new(File.expand_path('fixtures/hello.txt', __dir__)) }
    let!(:string_io) { StringIO.new("hello world!") }

    it "uploads a file" do
      expect(HTTP).to receive(:post) do |url, args|
        expect(url).to match(/^.+\/sendDocument$/)

        expect(args[:json]).to be_nil
        expect(args[:form]).to be_present
        expect(args[:form][:chat_id]).to eq(chat_id)

        document = args[:form][:document]
        expect(document).to be_present
        expect(document.to_s.strip).to eq("hello!")
        expect(document.filename).to eq("hello.txt")
      end.and_return(double(code: 200, parse: "document_response"))

      response = subject.send_document document: TelegramWorkflow::InputFile.new(file)
      expect(response).to eq("document_response")
    end

    it "uploads string IO" do
      expect(HTTP).to receive(:post) do |url, args|
        expect(url).to match(/^.+\/sendDocument$/)

        expect(args[:json]).to be_nil
        expect(args[:form]).to be_present
        expect(args[:form][:chat_id]).to eq(chat_id)

        document = args[:form][:document]
        expect(document).to be_present
        expect(document.to_s).to eq("hello world!")
        expect(document.filename).to start_with("stream-")
        expect(document.content_type).to eq("application/octet-stream")
      end.and_return(double(code: 200, parse: "document_response"))

      response = subject.send_document document: TelegramWorkflow::InputFile.new(string_io)
      expect(response).to eq("document_response")
    end

    it "allows to change content type" do
      expect(HTTP).to receive(:post) do |_, args|
        expect(args[:form][:document].content_type).to eq("image/jpeg")
      end.and_return(double(code: 200, parse: "document_response"))

      response = subject.send_document document: TelegramWorkflow::InputFile.new(file, content_type: "image/jpeg")
      expect(response).to eq("document_response")
    end

    it "allows to change filename" do
      expect(HTTP).to receive(:post) do |_, args|
        expect(args[:form][:document].filename).to eq("hello.txt")
      end.and_return(double(code: 200, parse: "document_response"))

      response = subject.send_document document: TelegramWorkflow::InputFile.new(string_io, filename: "hello.txt")
      expect(response).to eq("document_response")
    end
  end

  context "with webhook url caching" do
    subject { described_class.new }
    let(:webhook_url) { TelegramWorkflow.config.webhook_url }

    after do
      FileUtils.remove_dir "tmp", true
    end

    it "correctly sets the url" do
      url = "https://test.telegram.webhook.url"
      expect(HTTP).to receive(:post).with(/^.+\/setWebhook$/, { json: hash_including(url: url) }).
        and_return(double(code: 200, parse: nil))

      expect { subject.set_webhook(url: url) }.to change { described_class::WebhookConfigPath.exist? }.to(true)
    end

    it "correctly deletes the url" do
      expect(HTTP).to receive(:post).with(/^.+\/deleteWebhook$/, kind_of(Hash)).
        and_return(double(code: 200, parse: nil))

      subject.delete_webhook
      config = described_class::WebhookConfigPath.read
      expect(Marshal.load(config)).to be_blank
    end

    it "correctly caches the url" do
      expect(HTTP).to receive(:post).
        with(/^.+\/setWebhook$/, { json: hash_including(url: webhook_url) }).
        once.
        and_return(double(code: 200, parse: nil))

      2.times { subject.__setup_webhook }
    end

    it "correctly caches the webhook params" do
      allowed_updates = %w(message edited_message)

      expect(HTTP).to receive(:post).
        with(/^.+\/setWebhook$/, { json: hash_including(url: webhook_url, allowed_updates: allowed_updates) }).
        once.
        and_return(double(code: 200, parse: nil))

      2.times { subject.__setup_webhook(webhook_url, allowed_updates: allowed_updates) }
    end

    it "correctly changes the url" do
      expect(HTTP).to receive(:post).
        with(/^.+\/setWebhook$/, { json: hash_including(url: webhook_url) }).
        once.
        and_return(double(code: 200, parse: nil))
      subject.__setup_webhook(webhook_url)

      new_url = "https://new.test.telegram.webhook.url"

      expect(HTTP).to receive(:post).
        with(/^.+\/setWebhook$/, { json: hash_including(url: new_url) }).
        once.
        and_return(double(code: 200, parse: nil))
      described_class.new.__setup_webhook(new_url)
    end

    it "correctly changes the webhook params" do
      allowed_updates = %w(edited_message)

      expect(HTTP).to receive(:post).
        with(/^.+\/setWebhook$/, { json: hash_including(url: webhook_url, allowed_updates: allowed_updates) }).
        once.
        and_return(double(code: 200, parse: nil))
      subject.__setup_webhook(webhook_url, allowed_updates: allowed_updates)

      new_allowed_updates = allowed_updates + %w(message)

      expect(HTTP).to receive(:post).
        with(/^.+\/setWebhook$/, { json: hash_including(url: webhook_url, allowed_updates: new_allowed_updates) }).
        once.
        and_return(double(code: 200, parse: nil))
      described_class.new.__setup_webhook(webhook_url, allowed_updates: new_allowed_updates)
    end

    it "resets allowed_updates setting" do
      webhook_params = { allowed_updates: %w(edited_message) }

      expect(HTTP).to receive(:post).
        with(/^.+\/setWebhook$/, { json: hash_including(url: webhook_url, **webhook_params) }).
        once.
        and_return(double(code: 200, parse: nil))
      subject.__setup_webhook(webhook_url, webhook_params)

      new_webhook_params = {}

      expect(HTTP).to receive(:post).
        with(/^.+\/setWebhook$/, { json: hash_including(url: webhook_url, allowed_updates: []) }).
        once.
        and_return(double(code: 200, parse: nil))
      described_class.new.__setup_webhook(webhook_url, new_webhook_params)
    end
  end

  context "with deprecated action" do
    it "allows to call deprecated actions" do
      expect(HTTP).to receive(:post).
        with(/^.+\/kickChatMember$/, { json: { chat_id: chat_id } }).
        and_return(double(code: 200, parse: "kick_chat_member_response"))

      expect(TelegramWorkflow.config.logger).to receive(:warn).with(
        "[TelegramWorkflow] kickChatMember action is deprecated. Use banChatMember action instead."
      )

      expect(subject.kick_chat_member).to eq("kick_chat_member_response")
    end

    it "allows to call new actions" do
      expect(HTTP).to receive(:post).
        with(/^.+\/banChatMember$/, { json: { chat_id: chat_id } }).
        and_return(double(code: 200, parse: "ban_chat_member_response"))

      expect(TelegramWorkflow.config.logger).not_to receive(:warn)
      expect(subject.ban_chat_member).to eq("ban_chat_member_response")
    end
  end
end
