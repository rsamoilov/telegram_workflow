## Description

This is a fully working example of a bot which allows you to book an appointment with a doctor.

The following diagram will help you understand the bot's flow:
<p>
  <img src="https://github.com/rsamoilov/telegram_workflow/blob/master/example/flow.jpg" width="400">
</p>

## Running the bot

First, open [main.rb](main.rb) and configure the bot with your API token:

```diff
TelegramWorkflow.configure do |config|
- config.api_token = <YOUR_TOKEN>
+ config.api_token = "123456780:ABCDE_my-token"
end
```

Next, run the bot:

```
bundle
ruby main.rb
```

## Configuration

Every Bot workflow begins with **`on_message`** callback in a `start_action`.
There's no need to store current user data in session in this example, so we simply redirect to the `ListActions` action, which will be our "main" action.

```ruby
class Actions::Start < TelegramWorkflow::Action
  def initial
    on_message do
      redirect_to Actions::ListActions
    end
  end
end
```

Next, the Telegram client can be customized. We want to use Telegram's [InlineKeyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating) to provide a user with a list of available actions.

Let's encapsulate this inside our custom client class:

```ruby
class Client < TelegramWorkflow::Client
  def send_actions(message, actions)
    send_message text: message, reply_markup: { inline_keyboard: actions }
  end
end
```

Now, let's configure the gem:

```ruby
TelegramWorkflow.configure do |config|
  config.start_action = Actions::Start
  config.client = Client
  config.session_store = TelegramWorkflow::Stores::File.new
end
```

The last configuration parameter here is `session_store`. We are using `TelegramWorkflow::Stores::File` - a built-in implementation of persistent file store.

[getUpdates](https://core.telegram.org/bots/api#getupdates) method is used in this example to receive the updates:

```ruby
TelegramWorkflow.updates.each do |params|
  TelegramWorkflow.process(params)
end
```

After a user has sent a message, `TelegramWorkflow.process` will initialize the last processed action and step and then call `on_message` callback on it.

## Actions

Check out the bot's code under [actions](actions) folder.
