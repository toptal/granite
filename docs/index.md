# Granite Framework

Granite is a business actions architecture for Rails applications.

It's a combination of user interaction (attributes and validations), context (preconditions) and
permissions (authorization policies).

## What problems does Granite solve

Granite leverages patterns for improving productivity when developing a growing application.
Instead of bloating controller and model, you put business logic in e.g. app/actions directory.

These atomic actions process data and perform arbitrary operations upon user request or when
called programmatically, e.g. by a background worker or another action.

## Business actions

The central concept of Granite is a business action. Each business action can
start with a simple `execute_perform!` method.

### Hello world

Basically it is an active model-like class (form object) defined to execute a sequence of commands.
The simplest business action looks like this:

```ruby
class Action < Granite::Action
  private def execute_perform!(*)
    puts 'Hello World'
  end
end
```

There are a few ways of executing newly defined business action: using `#perform`, `#perform!` or `try_perform!` methods:
- `perform!` - raises exception in case of errors
- `perform` - returns `false` in case of errors
- `try_perform!` - similar to `perform!`, but doesn't run action if preconditions are not satisfied

### Transactions

Every action execution is wrapped in a DB transaction based on `ActiveRecord::Base.transaction(requires_new: true)`.

```irb
[1] pry(main)> Action.new.perform! # the same for `perform` and `try_perform!`
   (0.3ms)  BEGIN
Hello World
   (0.1ms)  COMMIT
=> true
```

You can use `Granite::Action.transaction` explicitly and wrap any logic in transaction:

```ruby
Granite::Action.transaction do
  some_other_logic
  Action.new.perform!
  AnotherAction.new.perform!
end
```

### Callbacks

#### `after_commit`

is triggered after DB transaction committed.

```ruby
class Action < Granite::Action
  ...

  after_commit do
    # any logic that rely on action results to be in the database
    # like schedule jobs
    puts 'after_commit triggered'
  end

  # OR
  # after_commit :method_to_trigger
end
```

```irb
[1] pry(main)> Action.new.perform!
   (0.3ms)  BEGIN
Hello World
   (0.1ms)  COMMIT
after_commit triggered
=> true
```

### before and after `execute_perform`

```ruby
class Action < Granite::Action
  ...

  set_callback(:execute_perform, :before) do
    puts 'before execute_perform'
  end

  set_callback(:execute_perform, :after, :after_execute_perform)

  def after_execute_perform
    puts 'after execute_perform'
  end
end
```

```irb
[1] pry(main)> Action.new.perform!
   (0.3ms)  BEGIN
before execute_perform
Hello World
after execute_perform
   (0.1ms)  COMMIT
=> true
```

### Performer

Every BA has a performer which can be assigned via `.as` class method before BA creation.

```ruby
MyAction.as(Admin.first).new(params)
```

Performer can be any Ruby object. By default performer is `nil`.

### Attributes

The next step is defining action attributes. There are several types of them and they are provided by `active_data` gem:

```ruby
class Action < Granite::Action
  attribute :name, String
  collection :ids, Integer

  private def execute_perform!(*)
    puts "Hello #{name}! We have the following ids: #{ids}'
  end
end
```

For detailed information on the available types and usage examples, check out [ActiveData documentation](https://github.com/pyromaniac/active_data#attributes).

The attributes behave pretty much as they do with `ActiveData` objects, except for `represents`:

#### Represents

In `ActiveData` objects, when a model attribute is exposed through `represents` and the AD object changes, the exposed attribute is updated right away, and Granite Actions update the represented attribute `before_validation`.

### Associations

Granite actions can also define several associations:

```ruby
class CreateBook < Granite::Action
  attribute :name, String
  references_one :author
  embeds_many :reviews
end
```

For more information on the associations available and usage examples, see [ActiveData documentation](https://github.com/pyromaniac/active_data#associations).

### NestedActions

Some business actions call other actions as part of their own action. For cases like that we should define memoizable method that
returns instance of subaction.

```ruby
memoize def subaction
  MySubactionClass.new
end
```

Subactions will validate their data and check preconditions when they're performed. This however should not be relied on
and it's better to check preconditions of subaction when precondtions of main action are checked and validate subaction
when main action is validated. For this we use:

```ruby
precondition embedded: :subaction
validates :subaction, nested: true
```

### Subject

Subject definition does three things: defines `references_one` association, aliases its methods
to common names (`subject` and `subject_id`) and modifies action initializer, providing ability to pass subject as the first
argument and restricting subject-less action initialization.

```ruby
class Action < Granite::Action
  subject :user

  private def execute_perform!(*); end
end
```

```irb
[1] pry(main)> Action.new # => ArgumentError
[2] pry(main)> Action.new(User.first)
=> #<Action user: #<ReferencesOne #<User id: 1...>, user_id: 1>
[3] pry(main)> Action.new(1)
=> #<Action user: #<ReferencesOne #<User id: 1...>, user_id: 1>
[4] pry(main)> Action.new(user: User.first)
=> #<Action user: #<ReferencesOne #<User id: 1...>, user_id: 1>
[5] pry(main)> Action.new(subject: User.first)
=> #<Action user: #<ReferencesOne #<User id: 1...>, user_id: 1>
[6] pry(main)> Action.new(user_id: 1)
=> #<Action user: #<ReferencesOne #<User id: 1...>, user_id: 1>
[7] pry(main)> Action.new(id: 1)
=> #<Action user: #<ReferencesOne #<User id: 1...>, user_id: 1>
```

As you can see `#user` is aliased to `#subject` and `#user_id` is aliased to `#id`. Also subject call takes any combination of `references_one` possible options.

### Policies, preconditions, validations

The main question is how to choose suitable construction. Here are simple rules:

1. If condition is dependent on any of user provided attribute values except subject - it is a validation.
2. If condition depends on subject or any value found depending on subject - it is a precondition.
3. Otherwise if it is related to performer - it is a policy.

#### Policies

Performing restrictions for the performer:

```ruby
class Action < Granite::Action
  allow_if { performer.present? }
  allow_self # equal to allow_if { performer == subject }
end
```

Policies support strategies. If default [AnyStrategy](lib/granite/action/policies/any_strategy.rb) doesn't fit your needs
you can use [AlwaysAllowStrategy](lib/granite/action/policies/always_allow_strategy.rb), [RequiredPerformerStrategy](lib/granite/action/policies/required_performer_strategy.rb)
or write your own. You can use new strategy like that:

```ruby
class Action < Granite::Action
  self._policies_strategy = MyCustomStrategy
end
```

#### Preconditions

This is a subject-related prevalidation, working in the same way as validations with blocks,
but `decline_with` method is used instead of `errors.add`:

```ruby
precondition do
  decline_with(:inactive) unless subject.active?
end
```

In case you have subactions which you perform inside your action you can
check subaction preconditions by simple embedding:
```ruby
precondition embedded: :my_custom_action
```

You can specify conditions when precondition block should be executed with `:if` (and only `:if`) statement.
```ruby
precondition if: -> { subject.active? } do
  decline_with(:too_young) if subject.age < 30
end
```

#### Validations

You are able to use any of ActiveModel-provided validations.

##### Context validations

Context validations ([see the note about the `context` argument](http://api.rubyonrails.org/classes/ActiveModel/Validations.html#method-i-valid-3F)) are supported and embraced by Granite. You can specify the `on:` key with any validation to declare a context in which the validation should be executed. Such validations will be triggered only when the provided context was specified explicitly.

To specify a context with the built-in ActiveModel methods `valid?` and `invalid?`, simply provide the context as the first argument.

To specify a context with `perform`, `perform!`, or `try_perform!`, pass the name of the context as a keyword argument `context:`.

You should use context validations when a single action could be triggered in different scenarios (e.g. by a staff member and a user) and different validation behavior is required.

Consider this simplified business action for updating a portfolio of a user:

```ruby
class BA::User::UpdatePortfolio < Granite::Action
  subject :user

  represents :full_name, of: :subject

  validates :full_name, presence: true, on: :user

  private def execute_perform!(*)
    # ...
  end
end
```

To run a business action without context you can simply send the `perform!` message to the action. It won't require full_name to be present.
If you want a validation to be executed in this scope you can add context argument to perform call: `perform!(context: :user)`.

### Exceptions handling

Granite has built-in mechanism for exceptions handling (similar to `rescue_from` known from `ActionController`). You are able to register handlers for any exception type, like this:

```ruby
class Action < Granite::Action
  handle_exception ThirdPartyLib::APIError do |error|
    decline_with(:third_party_lib_failed)
  end

  private def execute_perform!(*)
    ThirdPartyLib.api_call
  end
end
```

Adding errors to action object is important, because each time handled exception is raised,
`Granite::Action::ValidationError` is raised.
Validation exception will have the same backtrace as original error.
Prefer this way over custom exception handling in private methods.

### I18n

There are special I18n rules working in action. If I18n identifier is prefixed with `.` (`t('.foobar')`) - then translations lookup happens in following order:
```
granite_action.#{granite_action_name}.foobar
granite_action.granite/action.foobar
foobar
```

Note that rules are different for [I18n lookup inside a projector context](#i18n-projectors-lookup).

### Generator

You can use granite generator to generate a starting point for your action. You have to pass name and path of action as first argument. Basic usage is:
`rails g granite SUBJECT/ACTION [PROJECTOR]`.
You can use `-C` or `--collection` option to generate collection action where subject is not known when initializing action.
You can pass a second argument to generator to specify projector name.

`rails g granite user/create`

      create  apq/actions/ba/user/create.rb
      create  apq/actions/ba/user/business_action.rb
      create  spec/apq/actions/ba/user/create_spec.rb

`rails g granite user/create -C`

      create  apq/actions/ba/user/create.rb
      create  spec/apq/actions/ba/user/create_spec.rb

`rails g granite user/create simple`

      create  apq/actions/ba/user/create/simple
      create  apq/actions/ba/user/create.rb
      create  apq/actions/ba/user/business_action.rb
      create  spec/apq/actions/ba/user/create_spec.rb


