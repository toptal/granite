# Granite

Granite is an alternative Rails application architecture framework.

[![Build Status](https://travis-ci.org/toptal/granite.svg?branch=master)](https://travis-ci.org/toptal/granite)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'granite'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install granite

## Usage

Please see [our official documentation](https://toptal.github.io/granite/) or check the
[granite application example](https://github.com/toptal/example_granite_application).

### Versioning

We use [semantic versioning](https://semver.org/) for our [releases](https://github.com/toptal/granite/releases).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/toptal/granite.

This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

### Running specs

To run specs you can run

```
bin/setup
rspec
```

Or, alternatively you can copy and adapt the `spec/support/database.yml` for your environment:

```
cp spec/support/database.yml.example spec/support/database.yml
[Necessary customization here]
psql -c 'create database granite;' -U granite
rspec
```

### Using Granite's Rubocop config

Add this to your Rubocop config file:

```
require:
  - rubocop-granite
```

This will add config for `Lint/UselessAccessModifier` to treat `projector` as separate context. It is equivalent to:

```
Lint/UselessAccessModifier:
  ContextCreatingMethods:
    - projector
```

## License

Granite is released under the [MIT License](https://opensource.org/licenses/MIT).
