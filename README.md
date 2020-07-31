# TelegramWorkflow

[![Build Status](https://travis-ci.org/rsamoilov/telegram_workflow.svg?branch=master)](https://travis-ci.org/rsamoilov/telegram_workflow)
[![Coverage Status](https://coveralls.io/repos/github/rsamoilov/telegram_workflow/badge.svg?branch=master)](https://coveralls.io/github/rsamoilov/telegram_workflow?branch=master)
[![Maintainability](https://api.codeclimate.com/v1/badges/fd13239262e3550c2193/maintainability)](https://codeclimate.com/github/rsamoilov/telegram_workflow/maintainability)

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

## Documentation

Please see the [TelegramWorkflow wiki](https://github.com/rsamoilov/telegram_workflow/wiki) for more detailed documentation.

## Example

Check out an example of a bot under [example](example) folder.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rsamoilov/telegram_workflow. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/rsamoilov/telegram_workflow/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TelegramWorkflow project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/rsamoilov/telegram_workflow/blob/master/CODE_OF_CONDUCT.md).
