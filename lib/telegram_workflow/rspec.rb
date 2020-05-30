module TelegramActionExampleGroup
  def self.included(klass)
    klass.class_eval do
      klass.metadata[:type] = :telegram_action

      subject { double(client: spy, flow: spy) }

      let(:current_action) { described_class }
      let(:action_params) do
        {
          "update_id" => 111111111,
          "message" => {
            "message_id" => 200,
            "from" => {
              "id" => 112233445,
            },
            "text" => ""
          },
          "callback_query" => {
            "data" => ""
          },
          "inline_query" => {
            "query" => ""
          }
        }
      end

      before do
        TelegramWorkflow.config.session_store = TelegramWorkflow::Stores::InMemory.new
        TelegramWorkflow.config.start_action = TestStartAction
        send_message message_text: "/start"
      end

      include InstanceMethods
    end
  end

  module InstanceMethods
    def send_message(message_text: "", callback_data: "", inline_data: "")
      action_params["message"]["text"] = message_text
      action_params["callback_query"]["data"] = callback_data
      action_params["inline_query"]["query"] = inline_data
      yield action_params if block_given?

      workflow = TestFlow.new(action_params)
      workflow.example_group = self

      workflow.process
    end
  end

  class TestFlow < TelegramWorkflow::Workflow
    attr_accessor :example_group

    def client
      example_group.subject.client
    end

    def redirect_to(action_or_step, session_params = nil)
      super

      if session_params
        example_group.subject.flow.send(:redirect_to, action_or_step, session_params)
      else
        example_group.subject.flow.send(:redirect_to, action_or_step)
      end
    end
  end

  class TelegramWorkflow::Action
    def_delegators :@__workflow, :example_group
  end

  class TestStartAction < TelegramWorkflow::Action
    def initial
      on_message { redirect_to example_group.current_action }
    end
  end
end

RSpec.configure do |config|
  config.include TelegramActionExampleGroup,
    type: :telegram_action,
    file_path: %r(spec/telegram_actions)
end
