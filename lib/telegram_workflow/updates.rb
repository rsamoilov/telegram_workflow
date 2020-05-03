class TelegramWorkflow::Updates
  def initialize(params)
    @params = params
  end

  def enum
    Enumerator.new do |y|
      loop do
        updates = TelegramWorkflow::Client.new.get_updates(@params)["result"]
        updates.each do |update|
          y << update
        end

        @params.merge! offset: updates.last["update_id"] + 1
      end
    end
  end
end
