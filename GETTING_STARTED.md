# Granite

Table of Contents
=================

   * [Granite](#granite)
      * [Business actions](#business-actions)
         * [Hello world](#hello-world)
         * [Performer](#performer)
         * [Attributes](#attributes)
            * [Represents](#represents)
         * [Associations](#associations)
         * [NestedActions](#nestedactions)
         * [Subject](#subject)
         * [Policies, preconditions, validations](#policies-preconditions-validations)
            * [Policies](#policies)
            * [Preconditions](#preconditions)
            * [Validations](#validations)
               * [Context validations](#context-validations)
         * [Exceptions handling](#exceptions-handling)
         * [I18n](#i18n)
         * [Generator](#generator)
      * [Projectors](#projectors)
         * [Basics](#basics)
            * [I18n projectors lookup](#i18n-projectors-lookup)
         * [Decorator part](#decorator-part)
         * [Controller part](#controller-part)
         * [Projectors extension](#projectors-extension)
         * [Views](#views)
      * [Testing](#testing)
         * [Subject](#testing-subject)
         * [Projectors](#testing-projectors)
         * [Policies](#testing-policies)
         * [Preconditions](#testing-preconditions)
         * [Validations](#testing-validations)
         * [Perform](#testing-perform)


## Business actions

### Hello world

The central concept of Granite is a business action. Basically it is an active model-like class (form object) defined to execute a sequence of commands. The simplest business action looks like this:

```ruby
class Action < Granite::Action
  private def execute_perform!(*)
    puts 'Hello World'
  end
end
```

There are two ways of executing newly defined business action: using `#perform` or `#perform!` method:

```irb
[1] pry(main)> Action.new.perform!
   (0.3ms)  BEGIN
Hello World
   (0.1ms)  COMMIT
=> true
[2] pry(main)> Action.new.perform
   (0.2ms)  BEGIN
Hello World
   (0.2ms)  COMMIT
=> true
```

As you can see from log, every action execution is wrapped inside a DB transaction.
The main difference between these methods is: `#perform!` raises exception in case of errors and `#perform` simply returns `false`

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
    puts 'Hello World'
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


## Projectors


If you only want an abstraction for complex logic in your existing controller, you can just instantiate the Granite Action in the controller action:

```ruby
class MoviesController < ApplicationController
  # ...
  # Regular controller definition
  # ...
  def create
    BA::Movies::Create.as(current_user).new(some_params).perform!
  end
  # ...
end
```

However, this boilerplate code can quickly become rather repetitive, therefore it's recommended to use projectors.

The main purpose of projectors is to DRY copy-pasted controller actions and decorator methods. Projectors are the way to enable self-rendering of business actions into user interface.

### Basics

A projector file consists of two parts: a controller part and a decorator part. The decorator part is actually the projector class itself and the controller class is a nested class defined implicitly and accessible via `TestProjector.controller_class`.

```ruby
class TestProjector < Granite::Projector
end
```

Projectors must be mounted into actions and routes. It is possible to mount several projectors onto one action (for example we have to be able to execute a business action via a standard confirmation dialog or using inline editing) and also to have one projector mounted by several actions:

```ruby
class Action < Granite::Action
  projector :test
  # Or even name it as necessary:
  # projector :main, class_name: 'TestProjector'
end
```

When a projector is mounted onto the action, an inherited projector and a controller classes are created:

```irb
[1] pry(main)> Action.test
=> Action::TestProjector
[2] pry(main)> Action.test.controller_class
=> Action::TestController
[3] pry(main)> Action.test.action_class
=> Action(no attributes)
[4] pry(main)> Action.test.controller_class.action_class
=> Action(no attributes)
```

Projectors are mounted onto routes by specifying a path to the projector as a string.
 If a business action has multiple projectors, all of them have to be mounted separately in routes.
 If an action does not have a subject, it should be mounted explicitly inside the `collection` block:

When `granite` is called in routes - simply every controller of every projector mounted to the specified action is taken and its controller actions are mounted onto the routes. It is possible to mount particular projectors as well.

Projectors can only be mounted inside of resource and are mounted on `:member` if they have `subject` and on `:collection` if they don't:

```ruby
Application.routes.draw do
  resources :users, only: [:index] do
    collection do
      granite 'create#my_projector'
    end

    granite 'remove#my_projector'
  end
end
```

When you mount a projector, the route will be defined by the resources block you're in and the string provided.
The Granite action and projector will be infered by the parameter, split by the `#` character.
In the previous example, route would be `/users/create/:projector_action`, action would be `Create` and projector `MyProjector`.
`:projector_action` refers to the projector controller action. For instance:

```ruby
class FooProjector < Granite::Projector
  get :baz, as: '' do
    # ...
  end

  get :bar do
    render json: { cats: 'nice' }
  end
end

class Action < Granite::Action
  projector :foo
end

# config/routes.rb
# ...
resources :bunnies do
  granite 'action#foo'
end
```

In this case, the route '/bunnies/action/bar' would lead to `FooProjector#bar` action, and '/bunnies/action' would go to `FooProjector#baz`.

Normally projectors are mounted under `/:action/:projector_action` where `:action` is name of the BA and
`:projector_action` is mapped to projector controller action.

Note that if you have multiple projectors on the same action they might be using same routes. To prevent any clashes
between projectors it is recommended to mount the second projector with `projector_prefix: true`, which will mount this
projector under `/:projector_:action/:projector_action` instead of `/:action/:projector_action`. Same goes for path
helper method, it will be `projector_action_subject_path` instead of `action_subject_path`.

You can also customize mount path using `path: '/my_custom_path', as: :my_custom_action`.

It's also possible to restrict action HTTP verbs using `via: :post` (or `:get`, or any valid HTTP action).

It is possible to access projector instance from action instance by projector name as well:

```irb
[1] pry(main)> Action.new.test
=> #<Action::TestProjector:0x007f98bde9ac98 @action=#<Action (no attributes)>>
[2] pry(main)> Action.new.test.action
=> #<Action (no attributes)>
```

#### I18n projectors lookup

As in granite actions, there are special I18n rules working in projectors.
If I18n identifier is prefixed with `.` (`t('.foobar')`) - then translations lookup happens in following order:

```
granite_action.ba/#{granite_action_name}.#{granite_projector_name}.#{view_name}.foobar
granite_action.ba/#{granite_action_name}.#{granite_projector_name}.foobar
granite_action.base_action.#{granite_projector_name}.#{view_name}.foobar
granite_action.base_action.#{granite_projector_name}.foobar
granite_action.granite/action.#{granite_projector_name}.#{view_name}.foobar
granite_action.granite/action.#{granite_projector_name}.foobar
#{granite_projector_name}.#{view_name}.foobar
#{granite_projector_name}.foobar
```

### Decorator part

Since projector acts exactly like decorator does, it is possible to define helpers on projector instance level:

```ruby
class TestProjector < Granite::Projector
  def link
    h.link_to action.subject.full_name, action.subject
  end
end

class Action < Granite::Action
  projector :test
  subject :user
end
```

Inside the application it would be possible to call it like this:

```ruby
Action.new(User.first).test.link
# => "<a href=\"/user/112014\">Sebastián López Alfonso</a>"
```

### Controller part

The main purpose of a controller is to serve actions, but since we have to detect controller actions automatically in order to dispatch requests to them, we need a small DSL here:

```ruby
class TestProjector < Granite::Projector
  get :help do
    # render a view that shows help
  end

  get :form, as: '' do
    # render a form. This is a default `get` action for this controller
  end

  post :perform, as: '' do
    # process the form. This is a default `post` action for this controller
  end
end
```

The first thing here is a verb definition: it is possible to use any REST verb. The second thing is a mount point name to make routes look beautiful. It is provided with the `:as` option. You'll probably want to set it to empty string so that the actual controller action is not part of the URL, since the name of the business action is.

For instance, if we mounted the `BA::Company::Create` business action that had a projector with `perform` controller action, the path to the action by default would have been `create/perform`. By adding `as: ''` to the `perform` action definition we change the path to `create`.

Please keep in mind that provided code defines methods called `help`, `form`, and `perform` in the `controller_class`.

Note that calling `render` inside those blocks does not render the view within the application layout implicitly. To do so, you need to pass `layout: 'application'` to the `render` call.

#### Customizations

The controller is inherited from `Granite::Controller` which by default inherits from `ActionController::Base` this can be customized with initializer:
```ruby
Granite.tap do |m|
  m.base_controller = 'ApplicationController'
end
```

To set performer for granite actions implement `projector_performer`, for example:

```ruby
alias projector_performer current_user
```
  
`Granite::Controller` can be customized further after `rails generate granite:install_controller`, the original controller will be installed in `app/controllers/granite/controller.rb`.

#### Handling policies not allowed

When action policies are not satisfied action will raise an exception `Granite::Action::NotAllowedError`, it should be handled in the `base_controller_class`:

```ruby
  rescue_from Granite::Action::NotAllowedError do |exception|
    ...
  end
```

### Projectors extension

Since we are creating projector subclasses when mounting to business actions — there should be an ability to extend and modify them. This can be easily achieved by passing a block to the projector mount declaration:

```ruby
class Action < Granite::Action
  projector :test do
    controller_class.before_action { ... }

    def link_class
      'super-link'
    end
  end
end
```

This is useful for providing exact projector configuration or even controller extensions. In the most cases it would be preferable to derive a new projector from a standard one.

### Views

Views are used the same way as for usual controllers, but stored and inherited in slightly different way: basic views are stored in `apq/projectors/#{projector_name}` directory.

If you need to redefine any template in particular action - just put it near the action: e.g. `apq/actions/ba/#{action_name}/#{projector_name}` for `BA::ActionName.projector_name` projector

## Testing

Granite has multiple helpers for your rspec tests. Add `require 'granite/rspec'` to your `rails_helper.rb` in order
to use them.
All specs that live in `spec/apq/actions/` will get tagged with `:granite_action` type and will have access to granite
action specific helpers.
All specs that live in `spec/apq/projectors/` will get tagged with `:granite_projector` type and will have access to
granite projector specific helpers.

<h3 id="testing-subject">Subject</h3>

```ruby
subject(:action) { described_class.as(performer).new(user, attributes) }
let(:user) { User.new }
let(:attributes) { {} }
```

<h3 id="testing-projectors">Projectors</h3>

```ruby
it { is_expected.to have_projector(:simple) }
```

Test overridden projector methods:

```ruby
describe 'projectors', type: :granite_projector do
  subject { action.modal }
  projector { described_class.modal }

  its(:perform_success_response) { is_expected.to eq(my_success: 'yes') }
end
```

<h3 id="testing-policies">Policies</h3>

```ruby
subject { described_class.as(User.new).new }
it { is_expected.to be_allowed }
```

<h3 id="testing-preconditions">Preconditions</h3>

```ruby
context 'correct initial state' do
  it { is_expected.to satisfy_preconditions }
end

context 'incorrect initial state' do
  let(:company) { build_stubbed(:company, :active) }
  it { is_expected.not_to satisfy_preconditions.with_message("Some validation message")}
  it { is_expected.not_to satisfy_preconditions.with_messages(["First validation message", "Second validation message"])}
end
```

<h3 id="testing-validations">Validations</h3>

Validations tests are no different to ActiveRecord models tests

<h3 id="testing-perform">Perform</h3>

Run the action using `perform!` to test side-effects:

```ruby
specify { expect { perform! }.to change(User, :count).by(1) }
```
