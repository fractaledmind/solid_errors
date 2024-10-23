# Solid Errors

<p>
  <a href="https://rubygems.org/gems/solid_errors">
    <img alt="GEM Version" src="https://img.shields.io/gem/v/solid_errors?color=168AFE&include_prereleases&logo=ruby&logoColor=FE1616">
  </a>
  <a href="https://rubygems.org/gems/solid_errors">
    <img alt="GEM Downloads" src="https://img.shields.io/gem/dt/solid_errors?color=168AFE&logo=ruby&logoColor=FE1616">
  </a>
  <a href="https://github.com/testdouble/standard">
    <img alt="Ruby Style" src="https://img.shields.io/badge/style-standard-168AFE?logo=ruby&logoColor=FE1616" />
  </a>
  <a href="https://github.com/fractaledmind/solid_errors/actions/workflows/main.yml">
    <img alt="Tests" src="https://github.com/fractaledmind/solid_errors/actions/workflows/main.yml/badge.svg" />
  </a>
  <a href="https://github.com/sponsors/fractaledmind">
    <img alt="Sponsors" src="https://img.shields.io/github/sponsors/fractaledmind?color=eb4aaa&logo=GitHub%20Sponsors" />
  </a>
  <a href="https://ruby.social/@fractaledmind">
    <img alt="Ruby.Social Follow" src="https://img.shields.io/mastodon/follow/109291299520066427?domain=https%3A%2F%2Fruby.social&label=%40fractaledmind&style=social">
  </a>
  <a href="https://twitter.com/fractaledmind">
    <img alt="Twitter Follow" src="https://img.shields.io/twitter/url?label=%40fractaledmind&style=social&url=https%3A%2F%2Ftwitter.com%2Ffractaledmind">
  </a>
</p>


Solid Errors is a DB-based, app-internal exception tracker for Rails applications, designed with simplicity and performance in mind. It uses the new [Rails error reporting API](https://guides.rubyonrails.org/error_reporting.html) to store uncaught exceptions in the database, and provides a simple UI for viewing and managing exceptions.

> [!WARNING]
> The current point release of Rails (7.1.3.2) has a bug which severely limits the utility of Solid Errors. Exceptions raised during a web request *are not* reported to Rails' error reporter. There is a fix in the `main` branch, but it has not been released in a new point release. As such, Solid Errors is **not** production-ready unless you are running Rails from the `main` branch or until a new point version is released and you upgrade.
> The original bug report can be found [here](https://github.com/rails/rails/issues/51002) and the pull request making the fix is [here](https://github.com/rails/rails/pull/51050). I will try to backport the fix into the gem directly, but I haven't quite figured it out yet.


## Installation

Install the gem and add to the application's Gemfile by executing:
```bash
$ bundle add solid_errors
```

If bundler is not being used to manage dependencies, install the gem by executing:
```bash
$ gem install solid_errors
```

After installing the gem, run the installer:
```bash
$ rails generate solid_errors:install
```

This will create the `db/errors_schema.rb` file.

You will then have to add the configuration for the errors database in `config/database.yml`. If you're using sqlite, it'll look something like this:

```yaml
production:
  primary:
    <<: *default
    database: storage/production.sqlite3
  errors:
    <<: *default
    database: storage/production_errors.sqlite3
    migrations_paths: db/errors_migrate
```

...or if you're using MySQL/PostgreSQL/Trilogy:

```yaml
production:
  primary: &primary_production
    <<: *default
    database: app_production
    username: app
    password: <%= ENV["APP_DATABASE_PASSWORD"] %>
  errors:
    <<: *primary_production
    database: app_production_errors
    migrations_paths: db/errors_migrate
```

> [!NOTE]
> Calling `bin/rails solid_errors:install` will automatically add `config.solid_errors.connects_to = { database: { writing: :errors } }` to `config/environments/production.rb`, so no additional configuration is needed there (although you must make sure that you use the `errors` name in `database.yml` for this to match!). But if you want to use Solid Errors in a different environment (like staging or even development), you'll have to manually add that `config.solid_errors.connects_to` line to the respective environment file. And, as always, make sure that the name you're using for the database in `config/database.yml` matches the name you use in `config.solid_errors.connects_to`.

Then run `db:prepare` in production to ensure the database is created and the schema is loaded.

Then mount the engine in your `config/routes.rb` file:
```ruby
authenticate :user, -> (user) { user.admin? } do
  mount SolidErrors::Engine, at: "/solid_errors"
end
```

> [!NOTE]
> Be sure to [secure the dashboard](#authentication) in production.

## Usage

All exceptions are recorded automatically. No additional code required.

Please consult the [official guides](https://guides.rubyonrails.org/error_reporting.html) for an introduction to the error reporting API.

There are intentionally few features; you can view and resolve errors. That’s it. The goal is to provide a simple, lightweight, and performant solution for tracking exceptions in your Rails application. If you need more features, you should probably use a 3rd party service like [Honeybadger](https://www.honeybadger.io/), whose MIT-licensed [Ruby agent gem](https://github.com/honeybadger-io/honeybadger-ruby) provided a couple of critical pieces of code for this project.

### Manually reporting an Error

Errors can be added to Solid Errors via the [Rails error reporter](https://guides.rubyonrails.org/error_reporting.html).

There are [three ways](https://guides.rubyonrails.org/error_reporting.html#using-the-error-reporter) you can use the error reporter:

`Rails.error.handle` will report any error raised within the block. It will then swallow the error, and the rest of your code outside the block will continue as normal.

```ruby
result = Rails.error.handle do
  1 + '1' # raises TypeError
end
result # => nil
1 + 1 # This will be executed
```

`Rails.error.record` will report errors to all registered subscribers and then re-raise the error, meaning that the rest of your code won't execute.

```ruby
Rails.error.record do
  1 + '1' # raises TypeError
end
1 + 1 # This won't be executed
```

You can also manually report errors by calling `Rails.error.report`:

```ruby
begin
  # code
rescue StandardError => e
  Rails.error.report(e)
end
```

All 3 reporting APIs (`#handle`, `#record`, and `#report`) support the following options, which are then passed along to all registered subscribers:

* `handled`: a Boolean to indicate if the error was handled. This is set to `true` by default. `#record` sets this to `false`.
* `severity`: a Symbol describing the severity of the error. Expected values are: `:error`, `:warning`, and `:info`. `#handle` sets this to `:warning`, while `#record` sets it to `:error`.
* `context`: a Hash to provide more context about the error, like request or user details
* `source`: a String about the source of the error. The default source is `"application"`. Errors reported by internal libraries may set other sources; the Redis cache library may use "redis_cache_store.active_support", for instance. Your subscriber can use the source to ignore errors you aren't interested in.

```ruby
Rails.error.handle(context: { user_id: user.id }, severity: :info) do
  # ...
end
```

### Configuration

You can configure Solid Errors via the Rails configuration object, under the `solid_errors` key. Currently, 6 configuration options are available:

* `connects_to` - The database configuration to use for the Solid Errors database. See [Database Configuration](#database-configuration) for more information.
* `username` - The username to use for HTTP authentication. See [Authentication](#authentication) for more information.
* `password` - The password to use for HTTP authentication. See [Authentication](#authentication) for more information.
* `sends_email` - Whether or not to send emails when an error occurs. See [Email notifications](#email-notifications) for more information.
* `email_from` - The email address to send a notification from. See [Email notifications](#email-notifications) for more information.
* `email_to` - The email address(es) to send a notification to. See [Email notifications](#email-notifications) for more information.
* `email_subject_prefix` - Prefix added to the subject line for email notifications. See [Email notifications](#email-notifications) for more information.

#### Database Configuration

`config.solid_errors.connects_to` takes a custom database configuration hash that will be used in the abstract `SolidErrors::Record` Active Record model. This is required to use a different database than the main app. For example:

```ruby
# Use a single separate DB for Solid Errors
config.solid_errors.connects_to = { database: { writing: :solid_errors, reading: :solid_errors } }
```

or

```ruby
# Use a separate primary/replica pair for Solid Errors
config.solid_errors.connects_to = { database: { writing: :solid_errors_primary, reading: :solid_errors_replica } }
```

#### Authentication

Solid Errors does not restrict access out of the box. You must secure the dashboard yourself. However, it does provide basic HTTP authentication that can be used with basic authentication or Devise. All you need to do is setup a username and password.

There are two ways to setup a username and password. First, you can use the `SOLIDERRORS_USERNAME` and `SOLIDERRORS_PASSWORD` environment variables:

```ruby
ENV["SOLIDERRORS_USERNAME"] = "frodo"
ENV["SOLIDERRORS_PASSWORD"] = "ikeptmysecrets"
```

Second, you can set the `SolidErrors.username` and `SolidErrors.password` variables in an initializer:

```ruby
# Set authentication credentials for Solid Errors
config.solid_errors.username = Rails.application.credentials.solid_errors.username
config.solid_errors.password = Rails.application.credentials.solid_errors.password
```

Either way, if you have set a username and password, Solid Errors will use basic HTTP authentication. If you have not set a username and password, Solid Errors will not require any authentication to view the dashboard.

If you use Devise for authentication in your app, you can also restrict access to the dashboard by using their `authenticate` constraint in your routes file:

```ruby
authenticate :user, -> (user) { user.admin? } do
  mount SolidErrors::Engine, at: "/solid_errors"
end
```

#### Email notifications

Solid Errors _can_ send email notifications whenever an error occurs, if your application has ActionMailer already properly setup to send emails. However, in order to activate this feature you must define the email address(es) to send the notifications to. Optionally, you can also define the email address to send the notifications from (useful if your email provider only allows emails to be sent from a predefined list of addresses) or simply turn off this feature altogether. You can also define a subject prefix for the email notifications to quickly identify the source of the error.

There are two ways to configure email notifications. First, you can use environment variables:

```ruby
ENV["SOLIDERRORS_SEND_EMAILS"] = true # defaults to false
ENV["SOLIDERRORS_EMAIL_FROM"] = "errors@myapp.com" # defaults to "solid_errors@noreply.com"
ENV["SOLIDERRORS_EMAIL_TO"] = "devs@myapp.com" # no default, must be set
ENV["SOLIDERRORS_EMAIL_SUBJECT_PREFIX"] = "[Application name][Environment]" # no default, optional
```

Second, you can set the values via the configuration object:

```ruby
# Set authentication credentials and optional subject prefix for Solid Errors
config.solid_errors.send_emails = true
config.solid_errors.email_from = "errors@myapp.com"
config.solid_errors.email_to = "devs@myapp.com"
config.solid_errors.email_subject_prefix = "[#{Rails.application.name}][#{Rails.env}]"
```

If you have set `send_emails` to `true` and have set an `email_to` address, Solid Errors will send an email notification whenever an error occurs. If you have not set `send_emails` to `true` or have not set an `email_to` address, Solid Errors will not send any email notifications.

### Examples

There are only two screens in the dashboard.

* the index view of all unresolved errors:

![image description](images/index-screenshot.png)

* and the show view of a particular error:

![image description](images/show-screenshot.png)

### Usage with API-only Applications

If your Rails application is an API-only application (generated with the `rails new --api` command), you will need to add the following middleware to your `config/application.rb` file in order to use the dashboard UI provided by Solid Errors:

```ruby
# /config/application.rb
config.middleware.use ActionDispatch::Cookies
config.middleware.use ActionDispatch::Session::CookieStore
config.middleware.use ActionDispatch::Flash
```

### Overwriting the views

You can find the views in [`app/views`](https://github.com/fractaledmind/solid_errors/tree/main/app/views).

```bash
app/views/
├── layouts
│   └── solid_errors
│       ├── _style.html
│       └── application.html.erb
└── solid_errors
    ├── error_mailer
    │   ├── error_occurred.html.erb
    │   └── error_occurred.text.erb
    ├── errors
    │   ├── _actions.html.erb
    │   ├── _error.html.erb
    │   ├── _row.html.erb
    │   ├── index.html.erb
    │   └── show.html.erb
    └── occurrences
        ├── _collection.html.erb
        └── _occurrence.html.erb
```

You can always take control of the views by creating your own views and/or partials at these paths in your application. For example, if you wanted to overwrite the application layout, you could create a file at `app/views/layouts/solid_errors/application.html.erb`. If you wanted to remove the footer and the automatically disappearing flash messages, as one concrete example, you could define that file as:

```erb
<!DOCTYPE html>
<html>
  <head>
    <title>Solid Errors</title>
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>

    <%= render "layouts/solid_errors/style" %>
  </head>
  <body class="pb-4">
    <main class="container mx-auto mt-4">
      <%= content_for?(:content) ? yield(:content) : yield %>
    </main>

    <div class="fixed top-0 left-0 right-0 text-center py-2">
      <% if notice.present? %>
        <p class="py-2 px-3 bg-green-50 text-green-500 font-medium rounded-lg inline-block">
          <%= notice %>
        </p>
      <% end %>

      <% if alert.present? %>
        <p class="py-2 px-3 bg-red-50 text-red-500 font-medium rounded-lg inline-block">
          <%= alert %>
        </p>
      <% end %>
    </div>
  </body>
</html>
```

## Sponsors

<p align="center">
  <em>Proudly sponsored by</em>
</p>
<p align="center">
  <a href="https://www.honeybadger.io?utm_source=fractaledmind&utm_medium=open-source&utm_campaign=solid_errors">
    <img src="https://honeybadger-static.s3.amazonaws.com/brand_assets/honeybadger_logo/honeybadger_logo.svg" width="575" />
  </a>
</p>

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fractaledmind/solid_errors. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/fractaledmind/solid_errors/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the SolidErrors project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/fractaledmind/solid_errors/blob/main/CODE_OF_CONDUCT.md).

