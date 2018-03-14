# New project setup

We're testing here with Rails version x. The following example can be found
here: https://github.com/toptal/example_granite_application

## Generating new project

This tutorial is using Rails version `5.1.4` and the first step is install it:

```bash
gem install rails -v=5.1.4
```

Now, with the proper Rails version, let's start a new project:

```bash
rails new library
cd library
```

Let's start setting up the database for development:
```bash
rails db:setup
```

### Setup devise

Let's add devise to control users access and have a simple control under logged
users. Adding it to `Gemfile`.

```ruby
gem 'devise'
```

Now, use bundle install to 

```bash
rails generate devise:install
```

And then, let's create a simple devise model to interact with:

```bash
rails generate devise user
```

!!! info
    If you get in any trouble in this section, please check the updated
    documentation on the official [website](https://github.com/plataformatec/devise).

### Setup granite

Add `granite` to your Gemfile:

```ruby
gem 'granite'
```

And `bundle install` again.

Add `require 'granite/rspec'` to your `rails_helper.rb`. Check more details on
the [testing](docs/testing.md) section.

!!! warning
    If you get in any trouble in this section, please
    [report an issue](https://github.com/toptal/granite/issues/new).
