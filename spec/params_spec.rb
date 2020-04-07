RSpec.describe TelegramWorkflow::Params do
  subject { described_class.new(params) }

  let!(:params) { {} }

  it "doesn't fail in case there are no required keys" do
    methods = %i(user chat_id message_text callback_data start?)

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

    it "correctly checks for start message" do
      expect(subject.start?).to be(false)

      params[:message][:text] = "/start"
      expect(subject.start?).to be(true)
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
  end

  context "#chat_id" do
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

      it "returns chat id" do
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

      it "returns chat id" do
        expect(subject.chat_id).to eq(chat_id)
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
