require "telegram_workflow/rspec"

module RSpecParamsSpec
  class ParamsSpy
    class << self
      attr_accessor :params
    end
  end

  class Start < TelegramWorkflow::Action
    def initial
      on_message do
        ParamsSpy.params = params
      end
    end
  end
end

RSpec.describe RSpecParamsSpec::Start, type: :telegram_action do
  let(:params) { RSpecParamsSpec::ParamsSpy.params }

  it "sends message text" do
    text = "message text"
    send_message message_text: text
    expect(params.message_text).to eq(text)
  end

  it "sends callback data" do
    data = "callback data"
    send_message callback_data: data
    expect(params.callback_data).to eq(data)
  end

  it "sends inline query" do
    query = "inline query"
    send_message inline_data: query
    expect(params.inline_data).to eq(query)
  end

  it "sends raw params" do
    name = "Test User"
    send_message { |params| params[:custom_data] = { name: name } }
    expect(params[:custom_data][:name]).to eq(name)
  end
end
