# TelegramWorkflow

[![Build Status](https://travis-ci.org/rsamoilov/telegram_workflow.svg?branch=master)](https://travis-ci.org/rsamoilov/telegram_workflow)
[![Coverage Status](https://coveralls.io/repos/github/rsamoilov/telegram_workflow/badge.svg?branch=coveralls)](https://coveralls.io/github/rsamoilov/telegram_workflow?branch=coveralls)

TelegramWorkflow is a simple utility to help you organize the code to create Telegram bots.

It includes the HTTP client, which implements the complete Telegram API and a set of helpers to improve
the development experience.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'telegram_workflow'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install telegram_workflow

## Core Concepts

### Actions

In Rails we split the logic to process the requests into Controllers and Actions.
Similar to this approach, the gem suggests to split the logic to process the bot requests into Actions and Steps.

This is how a simple action could look like:

```ruby
class Ping < TelegramWorkflow::Action
  def initial
    on_redirect do
      client.send_message text: "Say ping:"
    end

    on_message do
      client.send_message text: "pong"
    end
  end
end
```

What's going on here:
* An action is created by defining a class that inherits from `TelegramWorkflow::Action`.
* The action has `initial` step. Every action should have at lease this step.
* The step method defines two optional callbacks. The `on_redirect` callback is called once the flow gets into the initial step. `on_message` callback is being called once a user sends a message back to the bot.

### Redirection

`redirect_to` function allows to redirect between actions and steps, making it possible to create complex workflows.

```ruby
class SelectMovie < TelegramWorkflow::Action
  def initial
    on_redirect do
      client.send_message text: "Select a genre:"
    end

    on_message do
      flash[:genre] = params.message_text
      redirect_to :suggest
    end
  end

  def suggest
    on_redirect do
      suggested_movie = find_a_movie_based_on_a_genre(flash[:genre])
      client.send_message text: "You will love this one - #{suggested_movie.name}"
    end
  end
end
```

Here we ask a user to select a movie genre. When a user responds to the bot, the response is saved into a temporary store. After that, a message with the suggested movie is sent back to the user.

This was an example of redirection between steps. Let's now add another action to rate the movie:

```diff
class SelectMovie < TelegramWorkflow::Action
  def suggest
    on_redirect do
      ...
+     redirect_to RateMovie
    end
  end
end
```
```ruby
class RateMovie < TelegramWorkflow::Action
  def initial
    on_redirect do
      client.send_message text: "Rate the movie:"
    end

    on_message do
      # save the response
    end
  end
end
```

Here you can see an example of redirection to another action.
Having a bot logic split over such small actions improves code maintanability and allows to follow SRP.

## Global Objects

Each action has a set of globally accessible objects:

Object | Description
-------|------------
[params](README.md#params) | Instance of `TelegramWorkflow::Params`.
[client](README.md#client) | Instance of `TelegramWorkflow::Client`. Can be [customized](README.md#client-customization).
[session](README.md#session) | Persistent store to keep session data. Instance of `Hash`.
[flash](README.md#flash) | Temporary store to keep some data between different steps. Instance of `Hash`.

## Public API

### params

The `params` object encapsulates the logic to parse Telegram params.
It implements useful methods, like `message_text`, `callback_data` or `deep_link_payload` to fetch user submitted data from the params.

### client

This is an instance of `TelegramWorkflow::Client` class, which implements a complete Telegram Bot API.
The methods to access the API are called after raw Telegram API methods.
For example, if you needed to call a [sendLocation](https://core.telegram.org/bots/api#sendlocation) method, you would use the following code:

```ruby
client.send_location latitude: 40.748, longitude: -73.985, live_period: 120
```

`chat_id` parameter should be omitted.

### session

This is a persistent store to save the data associated with a user, e.g. current user's id, some settings or anything you would store in a session in a regular web application.

### flash

This is a temporary store to save the data between the steps. The data persists while redirecting between the steps, but **gets deleted automatically when redirecting to another action**.

### redirect_to(action_or_class, flash_params = {})

As you already know, this function allows to build complex workflows by redirecting between actions and steps.
The function expects either a symbol or instance of `Class` as a first argument. Passing a symbol will redirect to another step inside the current action. Passing instance of `Class` will redirect to another action.

```ruby
# redirect to a step
redirect_to :suggest

# redirect to an action
redirect_to RateMovie
```

Sometimes you will need to share some data between the actions. You could use `session` for this, but a more appropriate solution would be to have `redirect_to` function to preserve the flash between actions.
Check out this example:

```ruby
class AskForBirthday < TelegramWorkflow::Action
  def initial
    on_redirect do
      client.send_message text: "What year is your birthday?"
    end

    on_message do
      birthday = params.message_text.to_i
      redirect_to DisplayAge, birthday: birthday
    end
  end
end

class DisplayAge < TelegramWorkflow::Action
  def initial
    on_redirect do
      age = Date.today.year - flash[:birthday]
      client.send_message text: "You are #{age}!"
    end
  end
end
```

You can see that despite the fact that flash is being cleared when redirecting to another action, passing `birthday` value to the `redirect_to` call made it accessible via flash in the action we redirected to.

## Configuration

Configure the gem using the `TelegramWorkflow.configure` call.
The two required parameters are `start_action` and `api_token`.

```ruby
TelegramWorkflow.configure do |config|
  config.start_action = <Start Action Class>
  config.api_token = <Your Token>
end
```

Method | Default | Description
-------|---------|------------
api_token | | This is the token you get from `@botfather` to access the Telegram API.
start_action | | This is an entry-point action, which is called every time `/start` or `/startgroup` command is sent to the chat.  You cannnot redirect to this action or call it manually. Use it to set the things up, e.g. create a user record or store current user's id in the session.
session_store | `Rails.cache` or `InMemoryStore.new` | This is the session store. Default implementation stores session in memory, which means it will be reset after server shutdown. Can be [customized](README.md#customization). Use `TelegramWorkflow::Stores::File` for persistent file store.
logger | `Rails.logger` or `STDOUT` | Logger object. Can be [customized](README.md#customization).
client | `TelegramWorkflow::Client` | The object which implements Telegram API. Can be [customized](README.md#client-customization).
webhook_url | nil | The webhook url. Set it only if you are using webhooks for getting updates. TelegramWorkflow will create a webhook subscription automatically.

## Updates

The gem implements both methods of getting updates from the Telegram API.

### Webhooks

* Configure the gem with `webhook_url` value.
* Process the updates with the following code in your controller:

```ruby
class TelegramWebhooksController < ApplicationController
  def create
    TelegramWorkflow.process(params)
  end
end
```

### Long polling

* Make sure you don't configure the gem with `webhook_url` value.
* Run the following code:

```ruby
TelegramWorkflow.updates.each do |params|
  TelegramWorkflow.process(params)
end
```

Be aware that `TelegramWorkflow.updates.each` call is blocking.

Since most of the time will be spent on waiting for the Telegram API to respond, you might also want to process the updates in parallel:

```ruby
require "concurrent-ruby"

pool = Concurrent::CachedThreadPool.new

TelegramWorkflow.updates.each do |params|
  pool.post { TelegramWorkflow.process(params) }
end
```

## Customization

Object | Customization
-------|--------------
logger | An object that responds to `info` and `error` methods.
session_store | An object that responds to `read` and `write` methods. Refer to [InMemoryStore](lib/telegram_workflow/stores/in_memory.rb) class definition.
client | An object that responds to `new(chat_id)` method.

### Client Customization

Use this customization to abstract your action's code from the Telegram API implementation details.

Create a customized client:

```ruby
class MyClient < TelegramWorkflow::Client
  def send_prize_location(user)
    # this is an example call
    prize = user.find_last_prize

    send_venue latitude: prize.latitude,
      longitude: prize.longitude,
      address: prize.address
      title: "Collect the last prize here!",
      reply_markup: { keyboard: [[{ text: "Give me a hint" }], [{ text: "Give me anohter hint" }]] }
  end
end
```

Now, configure the gem to use the customized client:

```ruby
TelegramWorkflow.configure do |config|
  config.client = MyClient
end
```

Then, in your action:

```ruby
class FindPrize < TelegramWorkflow::Action
  def initial
    on_redirect do
      client.send_prize_location(current_user)
    end
  end
end
```

## Testing

Testing utility provides `send_message` helper to emulate messages sent into the chat. Currently it accepts either `message_text` or `callback_data` as arguments.

Also, `subject.client` and `subject.flow` spies are available to track redirects and calls to the API client inside your actions.
Store your tests under `spec/telegram_actions` or tag them with `type: :telegram_action`.

Suppose we have the following action:

```ruby
class AskForBirthday < TelegramWorkflow::Action
  def initial
    on_redirect do
      client.send_message text: "What year is your birthday?"
    end

    on_message do
      Birthday.create! date: params.message_text
      redirect_to DisplayAge
    end
  end
end
```

Now, let's add some tests for this action:

```ruby
require "telegram_workflow/rspec"

RSpec.describe AskForBirthday, type: :telegram_action do
  it "asks for user's birthday" do
    expect(subject.client).to have_received(:send_message).with(text: "What year is your birthday?")
    expect {
      send_message message_text: "10/10/2000"
    }.to change { Birthday.count }.by(1)

    expect(subject.flow).to have_received(:redirect_to).with(DisplayAge)
  end
end
```

As you can see, testing utility starts the flow automatically, calling `initial` step on `described_class`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rsamoilov/telegram_workflow. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/rsamoilov/telegram_workflow/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TelegramWorkflow project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/rsamoilov/telegram_workflow/blob/master/CODE_OF_CONDUCT.md).
