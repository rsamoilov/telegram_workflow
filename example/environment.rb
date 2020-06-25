require "telegram_workflow"
require "date"

module Actions
end

dependencies = %w(
  ./actions/*.rb
  ./client.rb
)
dependencies.each do |path|
  Dir[path].each { |path| require_relative path }
end
