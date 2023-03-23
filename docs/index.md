# Granite Framework

Granite is an architecture for business actions in Rails applications, combining user interaction (attributes and validations), context (preconditions), and permissions (authorization policies).

## What problems does Granite solve

Granite employs patterns to increase productivity in developing growing applications. Instead of bloating the controller and model, business logic is placed in the app/actions directory.

These atomic actions process data and execute arbitrary operations in response to user requests or programmatically, such as by a background worker or another action.

## Business actions

The fundamental concept of Granite is the business action, which can be initiated with a simple `execute_perform!` method.

### Hello World

In essence, a business action is an ActiveModel-like class (form object) designed to execute a sequence of commands. The basic business action takes the following form:

```ruby
class Action < Granite::Action
  private def execute_perform!(*)
    puts 'Hello World'
  end
end
```

There are several ways to execute a recently defined business action, including `#perform`, `#perform!`, or `try_perform!`:
1. `perform!` raises an exception when encountering errors.
2. `perform` returns `false` when encountering errors.
3. `try_perform!` is comparable to `perform!` but doesn't execute the action if preconditions are not met.

### Transactions

To ensure proper data management, each action execution is enclosed in a DB transaction using `ActiveRecord::Base.transaction(requires_new: true)`.

```irb
[1] pry(main)> Action.new.perform! # the same for `perform` and `try_perform!`
   (0.3ms)  BEGIN
Hello World
   (0.1ms)  COMMIT
=> true
```

You can explicitly use `Granite::Action.transaction` and encapsulate any logic within a transaction:

```ruby
Granite::Action.transaction do
  some_other_logic
  Action.new.perform!
  AnotherAction.new.perform!
end
```

### Callbacks

#### `after_initialize`

This callback is triggered after an action has been initialized.

```ruby
class Action < Granite::Action
  attribute :name, String

  after_initialize do
    self.name = 'Default'
  end

  # OR
  # after_initialize :method_to_trigger
end

Action.new.name
# => 'Default'
```

#### `after_commit`

This callback is triggered after DB transaction has been committed.

```ruby
class Action < Granite::Action
  ...

  after_commit do
    # any logic that relies on action results being in the database,
    # such as scheduling jobs
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

### Context and performer

Each business action has a context, represented by a hash that can be assigned using the `.with` class method before the business action is initialized. The context is typically used to pass the performer of the action, which is so common that specific methods are defined to access and set the `performer`.

```ruby
action = MyAction.with(performer: Admin.first).new(params)
action.ctx #=> #<Granite::ContextProxy::Data performer: Admin.first>
action.performer #=> Admin.first

action = MyAction.as(Admin.first).new(params)
action.ctx #=> #<Granite::ContextProxy::Data performer: Admin.first>
action.performer #=> Admin.first
```

If your application requires additional attributes in the context, you can override the `BaseAction.with` and `BaseProjector.with` methods.

```ruby
module GraniteContext
  class Data < Granite::ContextProxy::Data
    def initialize(performer: nil, custom: false)
      super(performer: performer)
      @custom = custom
    end
  end

  def with(data)
    Granite::ContextProxy::Proxy.new(self, GraniteContext::Data.wrap(data))
  end
end

BaseAction.extend GraniteContext
BaseProjector.extend GraniteContext

BaseAction.with(performer: performer, custom: true)
```

### Attributes

The next step involves defining action attributes, which come in various types provided by the `granite-form` gem:

```ruby
class Action < Granite::Action
  attribute :name, String
  collection :ids, Integer

  private def execute_perform!(*)
    puts "Hello #{name}! We have the following ids: #{ids}"
  end
end
```

For comprehensive information on the available types and usage examples, please refer to the [Granite Form documentation](https://github.com/toptal/granite-form#attributes).

The behavior of the attributes is similar to that of `Granite::Form` objects, with the exception of `represents`.

#### Representing

With Granite Form objects, when a model attribute is exposed via `represents` and the Active Record object changes, the exposed attribute is immediately updated. 

_In contrast_, Granite Actions use `assign_data` to update the represented attribute.

#### Assigning the data

`assign_data` can be used to set blocks and methods that are invoked before the business action is validated. In practice, it can be implemented as follows:

```ruby
class CreateBook < Granite::Action
  attribute :name, String
  attribute :year, Integer
  represents :author, of: :book
  
  assign_data :set_name
  assign_data do
    book.year = year
  end
  
  private def set_name
    book.name = name
  end
end
```

In this example, before the business action is validated, Granite will invoke the `assign_data` callbacks and set the book's author, name, and year (in that order).

### Associations

Granite actions can also define several associations:

```ruby
class CreateBook < Granite::Action
  attribute :name, String
  references_one :author
  embeds_many :reviews
end
```

For comprehensive information on the available associations and usage examples, please refer to the [Granite Form documentation](https://github.com/toptal/granite-form#associations).

### Nested actions

Some business actions call other actions as part of their own execution. In such cases, we need to define a memoizable method that returns an instance of the sub-action:

```ruby
memoize def subaction
  MySubactionClass.new
end
```

Sub-actions validate their data and check preconditions when performed. However, it is not recommended to rely on this behavior. It is better to validate the sub-action when the main action is validated and check the preconditions of the sub-action when the preconditions of the main action are checked. For this, we use:

```ruby
precondition embedded: :subaction
validates :subaction, nested: true
```

### Subject

The definition of the subject does three things:
1. Defines a `references_one` association.
2. Aliases its methods to common names (`subject` and `subject_id`)
3. Modifies the action initializer to provide the ability to pass the subject as the first argument and restricts subject-less action initialization.

Let's take a look to an example below:

```ruby
class Action < Granite::Action
  subject :user

  private def execute_perform!(*); end
end
```

```irb
pry(main)> Action.new 
=> ArgumentError

pry(main)> Action.new(User.first)
=> #<Action user: #<ReferencesOne #<User id: 1...>, user_id: 1>

pry(main)> Action.new(1)
=> #<Action user: #<ReferencesOne #<User id: 1...>, user_id: 1>

pry(main)> Action.new(user: User.first)
=> #<Action user: #<ReferencesOne #<User id: 1...>, user_id: 1>

pry(main)> Action.new(subject: User.first)
=> #<Action user: #<ReferencesOne #<User id: 1...>, user_id: 1>

pry(main)> Action.new(user_id: 1)
=> #<Action user: #<ReferencesOne #<User id: 1...>, user_id: 1>

pry(main)> Action.new(id: 1)
=> #<Action user: #<ReferencesOne #<User id: 1...>, user_id: 1>
```

Notice that the method `#user` has been assigned to the alias `#subject`, and `#user_id` to `#id`. Furthermore, a `subject` call takes any combination of `references_one` possible options.

### Policies, preconditions, and validations

When deciding how to structure policies, preconditions, and validations, there are some simple rules to follow:
1. If the condition depends on _any user-provided attribute values_ except for the subject, it is a **validation**.
2. If the condition depends on _the subject or any value that depends on the subject_, it is a **precondition**.
3. Otherwise, if it is _related to the performer_, choose a **policy**.

#### Policies

Policies are used to define restrictions on the performer of an action. The `allow_if` method can be used to specify a condition that must be met for the action to be allowed. 

For example, the following code specifies that an action can only be performed if the performer is present:

```ruby
class Action < Granite::Action
  allow_if { performer.present? }
  allow_self # equal to allow_if { performer == subject }
end
```

There is also an `allow_self` method that is equivalent to `allow_if { performer == subject }`, which allows an action to be performed by the subject itself.

Granite policies also support strategies:
1. By default, the [`AnyStrategy`](https://github.com/toptal/granite/blob/master/lib/granite/action/policies/any_strategy.rb) is used, which allows an action to be performed if any policy allows it.
2. Other built-in strategies include [`AlwaysAllowStrategy`](https://github.com/toptal/granite/blob/master/lib/granite/action/policies/always_allow_strategy.rb), which allows all actions, 
3. And [`RequiredPerformerStrategy`](https://github.com/toptal/granite/blob/master/lib/granite/action/policies/required_performer_strategy.rb), which requires that a performer be present for all actions. 

You can also write your own custom policy strategy.

To use a custom policy strategy, you can set the `_policies_strategy` class variable to the desired strategy, like so:

```ruby
class Action < Granite::Action
  self._policies_strategy = MyCustomStrategy
end
```

#### Preconditions

Preconditions are used for subject-related pre-validation and work similarly to validations with blocks. However, instead of using `errors.add`, the `decline_with` method is preferred. 

For example, you can use a precondition to check if the subject is active before performing an action:

```ruby
precondition do
  decline_with(:inactive) unless subject.active?
end
```

If you have sub-actions that are performed within your main action, you can easily check their preconditions by embedding them:

```ruby
precondition embedded: :my_custom_action
```

You can specify conditions for when the precondition block should be executed using the `:if` and `unless` statements:

```ruby
precondition if: -> { subject.active? } do
  decline_with(:too_young) if subject.age < 30
end
```

##### Preconditions as objects

The `precondition` method can also accept a class that inherits from `Granite::Action::Precondition`. When defining a precondition this way, you can pass additional parameters to the precondition object, making it more reusable. 

The precondition method with a class argument supports the same options (`:if` and `:unless`) as defining a precondition as a block:

```ruby
class AgeCheck < Granite::Action::Precondition
  description 'Must be old enough'

  def call(**)
    decline_with(:too_young) if subject.age < 30
  end
end
```

This precondition can be used like this:

```ruby
precondition AgeCheck, if: -> { subject.active? }
```

#### Validations

Granite supports using any of the validations provided by Active Model.

##### Context validations

Granite supports and encourages the use of [context validations](http://api.rubyonrails.org/classes/ActiveModel/Validations.html#method-i-valid-3F), which can be specified using the `on:` key with any validation to declare the context in which the validation should be executed. This means that these validations will only be triggered when the provided context is explicitly specified.

To specify a context when using the built-in ActiveModel methods `valid?` and `invalid?`, simply provide the context as the first argument. When using `perform`, `perform!`, or `try_perform!`, pass the name of the context as a keyword argument `context:`.

Context validations should be used when different validation behavior is required in different scenarios (e.g., by a staff member and a non-staff user). For example, consider a simplified business action for updating a user's portfolio:

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

By default, running this business action using `perform!` won't require the `full_name` attribute to be present. However, if you want to enforce this validation, you can add a context argument to the perform call: `perform!(context: :user)`.

### Exception handling

Granite provides a built-in mechanism for exception handling, similar to the `rescue_from` method used in Action Controller. You can register handlers for any exception type using the `handle_exception` method.

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
In the example provided, `ThirdPartyLib::APIError` is caught, and the handler block adds an error to the action object with the message `:third_party_lib_failed`. It's important to add errors to the action object because, when a handled exception is raised, `Granite::Action::ValidationError` is raised with the same backtrace as the original error.

### Dependency Injection

Dependency Injection is a programming technique that allows you to remove hard-coded dependencies from your code and instead provide them externally. Granite's default attribute assignment mechanism may not always be suitable for this, but you can use custom initializers to achieve DI:

```ruby
class Action < Granite::Action
  attribute :name, String

  private attr_reader :my_dep

  def initialize(*args, my_dep: Foo.new, **kwargs, &block)
    @my_dep = my_dep
    super(*args, **kwargs, &block)
  end
end

Action.new(name: "Jane")                  # uses default value for `my_dep'
Action.new(name: "Jane", my_dep: Bar.new) # uses custom value for `my_dep'
```

In the example code, `my_dep` is a dependency that is provided to the action through the initialize method, rather than being hardcoded in the attribute definition. The `my_dep` dependency is set to a default value of `Foo.new`, but it can be overridden by passing a `my_dep` keyword argument to the constructor.

By using this technique, you can easily provide dependencies to your Granite actions from an external source, making your code more modular and testable.

### I18n

When using the I18n feature, if an identifier is prefixed with a dot (t('.foobar')), translations will be looked up in the following order:

```
granite_action.#{granite_action_name}.foobar
granite_action.granite/action.foobar
foobar
```

It's important to note that the lookup rules are different when performing an I18n lookup within a projector context. See the section on [I18n lookup inside a projector context](projectors/#i18n-projectors-lookup) for more information.

### Generator

You can use the granite generator to create a starting point for your action. To do so, pass the name and path of your action as the first argument using the following syntax:

```
rails g granite SUBJECT/ACTION [PROJECTOR]
```

If you want to generate a collection action where the subject is not known at initialization, use the `-C` or `--collection` option.
You can also specify the projector name as a second argument when using the generator.

Here are some examples of using the rails g granite command:

1. `rails g granite user/create`

    This command generates a new action called "create" for the "user" `subject`. It creates three files: `apq/actions/ba/user/create.rb`, `apq/actions/ba/user/business_action.rb`, and `spec/apq/actions/ba/user/create_spec.rb`.

2. `rails g granite user/create -C`
   Adding the `-C` option generates a collection action where the subject is not known at initialization. This command generates two files: `apq/actions/ba/user/create.rb` and `spec/apq/actions/ba/user/create_spec.rb`.

3. `rails g granite user/create simple`
   Adding a second argument, such as "simple" specifies the name of the projector to use. This command generates a new directory called simple within the `apq/actions/ba/user/create directory`, as well as the same files as the first example: `apq/actions/ba/user/create.rb`, `apq/actions/ba/user/business_action.rb`, and `spec/apq/actions/ba/user/create_spec.rb`.

## Conclusion

We hope this introduction to Granite has piqued your interest and given you a glimpse into the power and simplicity of this framework. Give it a try and see how Granite can streamline your business logic and take your Ruby on Rails applications to the next level.
