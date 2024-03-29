RSpec.describe TelegramWorkflow::Params do
  subject { described_class.new(params.with_indifferent_access) }

  let!(:params) { {} }

  it "doesn't fail in case there are no required keys" do
    methods = %i(user chat message_text callback_data start?)

    methods.each do |method_name|
      expect(subject.send(method_name)).to be_falsey
    end
  end

  context "#message_text" do
    let!(:params) do
      {
        message: {
          text: "test message"
        }
      }
    end

    it "returns a message" do
      expect(subject.message_text).to eq("test message")
    end

    it "doesn't fail in case there's no message" do
      params[:message].delete(:text)
      expect(subject.message_text).to be_nil
    end

    it "returns edited message" do
      params[:edited_message] = params.delete(:message)
      expect(subject.message_text).to eq("test message")
    end
  end

  context "#start" do
    let!(:params) do
      {
        message: {}
      }
    end

    it "correctly identifies start message" do
      params[:message][:text] = "/start"
      expect(subject).to be_start

      params[:message][:text] = "/startgroup"
      expect(subject).to be_start

      params[:message][:text] = "/start PAYLOAD"
      expect(subject).to be_start

      params[:message][:text] = "/startgroup PAYLOAD"
      expect(subject).to be_start
    end

    it "correctly identifies a message with /start substring" do
      params[:message][:text] = "TEST /start MESSAGE"
      expect(subject).not_to be_start
    end

    it "correctly identifies a non-start message" do
      params[:message][:text] = "test message"
      expect(subject).not_to be_start
    end

    it "doesn't fail in case there's no message" do
      params[:message].delete(:text)
      expect(subject).not_to be_start
    end
  end

  context "#deep_link_payload" do
    let!(:params) do
      {
        message: {}
      }
    end

    it "correctly returns deep-link payload from start message" do
      params[:message][:text] = "/start PAYLOAD"
      expect(subject.deep_link_payload).to eq("PAYLOAD")
    end

    it "correctly returns deep-link payload from startgroup message" do
      params[:message][:text] = "/startgroup PAYLOAD"
      expect(subject.deep_link_payload).to eq("PAYLOAD")
    end

    it "correctly returns deep-link payload with spaces" do
      payload = "THIS IS A TEST PAYLOAD"
      params[:message][:text] = "/start #{payload}"
      expect(subject.deep_link_payload).to eq(payload)
    end

    it "doesn't return payload from non-start messages" do
      params[:message][:text] = "test message"
      expect(subject.deep_link_payload).to be_nil

      params[:message][:text] = "/test_command PAYLOAD"
      expect(subject.deep_link_payload).to be_nil

      params[:message][:text] = "TEST /start MESSAGE"
      expect(subject.deep_link_payload).to be_nil
    end

    it "returns nil on start message without payload" do
      params[:message][:text] = "/start"
      expect(subject.deep_link_payload).to be_nil
    end

    it "returns nil on startgroup message without payload" do
      params[:message][:text] = "/startgroup"
      expect(subject.deep_link_payload).to be_nil
    end

    it "returns empty string in case there's no message" do
      params[:message].delete(:text)
      expect(subject.deep_link_payload).to be_nil
    end
  end

  context "#command" do
    let!(:params) do
      {
        message: {}
      }
    end

    it "correctly identifies start command" do
      params[:message][:text] = "/start"
      expect(subject).to be_command

      params[:message][:text] = "/start PAYLOAD"
      expect(subject).to be_command
    end

    it "correctly identifies a command" do
      params[:message][:text] = "/get_stats"
      expect(subject).to be_command
    end

    it "correctly identifies a message" do
      params[:message][:text] = "a message"
      expect(subject).not_to be_command
    end

    it "correctly identifies a message with slashes" do
      params[:message][:text] = "a /test message"
      expect(subject).not_to be_command
    end

    it "doesn't fail in case there's no message" do
      params[:message].delete(:text)
      expect(subject).not_to be_command
    end
  end

  context "#callback_data" do
    let!(:params) do
      {
        callback_query: {
          data: "callback_1"
        }
      }
    end

    it "returns the callback data" do
      expect(subject.callback_data).to eq("callback_1")
    end

    it "returns nil in case there's no callback data" do
      params.delete(:callback_query)
      expect(subject.callback_data).to be_nil
    end
  end

  context "#user" do
    let!(:user_id) { 111111111 }
    let!(:language_code) { "end" }

    context "with message" do
      let!(:params) do
        {
          message: {
            from: {
              id: user_id,
              language_code: language_code
            }
          }
        }
      end

      it "returns user params" do
        expect(subject.user).to be_present
        expect(subject.user_id).to eq(user_id)
        expect(subject.language_code).to eq(language_code)
      end
    end

    context "with callback query" do
      let!(:params) do
        {
          callback_query: {
            from: {
              id: user_id,
              language_code: language_code
            }
          }
        }
      end

      it "returns user params" do
        expect(subject.user).to be_present
        expect(subject.user_id).to eq(user_id)
        expect(subject.language_code).to eq(language_code)
      end
    end

    context "with inline query" do
      let!(:params) do
        {
          channel_post: {
            from: {
              id: user_id,
              language_code: language_code
            }
          }
        }
      end

      it "returns user params" do
        expect(subject.user).to be_present
        expect(subject.user_id).to eq(user_id)
        expect(subject.language_code).to eq(language_code)
      end
    end

    context "with channel post" do
      let!(:params) do
        {
          inline_query: {
            from: {
              id: user_id,
              language_code: language_code
            }
          }
        }
      end

      it "returns user params" do
        expect(subject.user).to be_present
        expect(subject.user_id).to eq(user_id)
        expect(subject.language_code).to eq(language_code)
      end
    end

    context "with no user" do
      let!(:params) do
        {
          chat: {
            id: 11111,
          }
        }
      end

      it "returns user params" do
        expect(subject.user).to be_nil
        expect(subject.user_id).to be_nil
        expect(subject.language_code).to eq("en")
      end
    end
  end

  context "#chat" do
    let(:chat_id) { 2222 }

    context "with message" do
      let!(:params) do
        {
          message: {
            chat: {
              id: chat_id,
            }
          }
        }
      end

      it "returns chat params" do
        expect(subject.chat).to be_present
        expect(subject.chat_id).to eq(chat_id)
      end
    end

    context "with edited channel post" do
      let!(:params) do
        {
          edited_channel_post: {
            chat: {
              id: chat_id,
            }
          }
        }
      end

      it "returns chat params" do
        expect(subject.chat).to be_present
        expect(subject.chat_id).to eq(chat_id)
      end
    end
  end

  context "#inline_data" do
    let!(:query) { "test inline query" }

    context "with inline data" do
      let!(:params) do
        {
          inline_query: {
            query: query
          }
        }
      end

      it "returns inline query" do
        expect(subject.inline_data).to eq(query)
      end
    end

    context "without inline data" do
      let!(:params) { {} }

      it "doesn't fail" do
        expect(subject.inline_data).to be_nil
      end
    end
  end

  context "#[]" do
    let!(:params) do
      {
        extra_param: {
          key: "value"
        }
      }
    end

    it "allows to access raw params" do
      expect(subject[:extra_param][:key]).to eq("value")
    end
  end
end
