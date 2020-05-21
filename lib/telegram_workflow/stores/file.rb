require "dbm"

class TelegramWorkflow::Stores::File
  StorePath = Pathname.new("tmp/telegram_workflow/file_store")

  def initialize
    StorePath.dirname.mkpath unless StorePath.exist?
    @store = DBM.open(StorePath.to_s)
  end

  def read(key)
    @store[key.to_s]
  end

  def write(key, value)
    @store[key.to_s] = value
  end
end
