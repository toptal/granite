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

