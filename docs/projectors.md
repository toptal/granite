# Projectors

If you need a simpler way to handle complex logic in your existing controller, you can use the Granite action by calling it in the controller action:

```ruby
class MoviesController < ApplicationController
  # ...
  # Regular controller definition
  # ...
  def create
    BA::Movies::Create.with(performer: current_user).new(some_params).perform!
  end
  # ...
end
```

However, this code can quickly become repetitive, so it's recommended to use projectors instead.

Projectors are mainly used to avoid duplicating code in controller actions and decorator methods. They enable business actions to be rendered into a user interface more easily.

## Basics

A projector file has two parts: 

1. **Decorator part** is the projector class itself.

2. **Controller part** is a nested class defined implicitly and accessible via `TestProjector.controller_class`.

For example:

```ruby
class TestProjector < Granite::Projector
end
```

To mount projectors into actions and routes, you can use the projector method. It's possible to mount multiple projectors onto one action (e.g., if we need to execute a business action through a standard confirmation dialog or inline editing) or to have one projector mounted by several actions:

```ruby
class Action < Granite::Action
  projector :test
  
  # Alternatively, you can specify a custom name:
  # projector :main, class_name: 'TestProjector'
end
```

When a projector is mounted onto an action, an inherited projector and a controller class are created:

```irb
pry(main)> Action.test
=> Action::TestProjector

pry(main)> Action.test.controller_class
=> Action::TestController

pry(main)> Action.test.action_class
=> Action(no attributes)

pry(main)> Action.test.controller_class.action_class
=> Action(no attributes)
```

To mount projectors onto routes, you need to specify a path to the projector as a string. If a business action has multiple projectors, each of them must be mounted separately in the routes. If an action doesn't have a subject, it should be mounted explicitly inside the `collection` block:

When you call `granite` in the routes, every controller of every mounted projector for the specified action is taken, and its controller actions are mounted onto the routes. You can also mount specific projectors.

Projectors can only be mounted inside a resource, and they are mounted on `:member` if they have a `subject` and on `:collection` otherwise:

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

When you mount a projector onto a route, the route will be defined by the resources block and the string provided. The Granite action and projector will be inferred by the parameter, which is split by the `#` character.

For instance, in the previous code block, the route `/users/create/:projector_action` is created, where the action is `Create` and the projector is `MyProjector`. 

Next code block shows how the `:projector_action` refers to the projector controller action (`baz` and `bar`):

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

In this context, the route `/bunnies/action/bar` corresponds to the `bar` action in the `FooProjector`, and `/bunnies/action` leads to the `baz` action in the same `FooProjector`.

Usually, projectors are mounted under `/:action/:projector_action`, where `:action` is the name of the BA, and `:projector_action` is mapped to the projector controller action.

Please note that if you have multiple projectors for the same action, they might use the same routes. To avoid conflicts between projectors, it's recommended to mount the second projector with `projector_prefix: true`. This will mount the projector under `/:projector_:action/:projector_action` instead of `/:action/:projector_action`. The same goes for the path helper method, which will be `projector_action_subject_path` instead of `action_subject_path`.

You can also customize the mount path using `path: '/my_custom_path', as: :my_custom_action`.

It's also possible to restrict the HTTP verbs for actions using `via: :post` (or `:get`, or any valid HTTP-action).

Lastly, you can access the projector instance from the action instance using the projector name:

```irb
pry(main)> Action.new.test
=> #<Action::TestProjector:0x007f98bde9ac98 @action=#<Action (no attributes)>>

pry(main)> Action.new.test.action
=> #<Action (no attributes)>
```

### I18n projectors lookup

In Granite actions, there are special I18n rules that apply to projectors. When the I18n identifier is prefixed with a dot (`t('.foobar')`), translations are looked up in the following order:

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

## Decorator part

Since projectors behave like decorators, you can define helpers at the projector instance level. For example:

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

In your application, you can call this helper method like this:

```ruby
Action.new(User.first).test.link
# => "<a href=\"/user/112014\">Sebastián López Alfonso</a>"
```

This will generate a link to the `User` object's page with the user's full name as the link text. The `link` method is defined in the `TestProjector` and is called on the test projector instance that is associated with the `Action` object. The `h` helper method is provided by the projector instance and allows you to use Rails view helpers in your projector methods.

## Controller part

The primary role of a controller is to serve actions, but in order to automatically detect controller actions and dispatch requests to them, we need a small DSL. Here's an example:

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

The first part of this code is the verb definition, which can be any REST verb. The second part is the mount point name to create a beautiful URL. You can set it using the `:as` option, and it's recommended to set it to an empty string so that the actual controller action isn't part of the URL.

For example, if you mounted the `BA::Company::Create` business action that had a projector with a `perform` controller action, the default path to the action would be `create/perform`. By adding `as: ''` to the `perform` action definition, you can change the path to `create`.

Note that the provided code defines methods called `help`, `form`, and `perform` in the `controller_class`. Also, keep in mind that calling `render` inside those blocks doesn't implicitly render the view within the application layout. To do so, you need to pass `layout: 'application'` to the `render` call.

### Customizations

The `Granite::Controller` is a subclass of `ActionController::Base` by default. However, it can be customized by changing the base_controller attribute in the Granite module's initializer. For example, to change the base controller to `ApplicationController`, you can do the following:

```ruby
Granite.tap do |m|
  m.base_controller = 'ApplicationController'
end
```

In order to set the performer for Granite actions, you can implement the `projector_performer` method. For example, if you want to use the `current_user` method as the performer for all Granite actions, you can do the following:

```ruby
def projector_performer
  current_user
end
```

It's worth noting that `Granite::Controller` can be further customized after running the `rails generate granite:install_controller` command. The original controller will be installed in `app/controllers/granite/controller.rb`, which can be modified to fit your specific needs.

### Handling policy exception

When an action's policies are not satisfied, Granite raises a `Granite::Action::NotAllowedError` exception. To handle this exception in the `base_controller_class`, you can use the `rescue_from` method like this:

```ruby
class ApplicationController < ActionController::Base
  rescue_from Granite::Action::NotAllowedError do |exception|
    # Handle the exception
  end
end
```

Inside the block, you can define how to handle the exception, for example by rendering an error page or redirecting the user to a different page.

## Extending projectors

To provide more flexibility in customizing projectors, Granite allows passing a block to the projector declaration when mounting to business actions. This block can be used to configure the projector or even extend its controller class.

Here's an example:

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

In this example, the `before_action` hook is added to the controller class and a new method `link_class` is defined.  While using a block to modify projectors is useful for small changes, it's often preferable to derive a new projector from a standard one for more significant modifications.

## Views

Views for projectors are used in the same way as views for usual controllers but are stored and inherited differently. Basic views for projectors are stored in `apq/projectors/#{projector_name}` directory.

If you need to redefine a specific template for a particular action, you can do so by placing the template in `apq/actions/ba/#{action_name}/#{projector_name}` for `BA::ActionName.projector_name` projector.
