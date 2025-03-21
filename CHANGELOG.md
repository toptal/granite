## Next

## v0.17.5

* Support for Rails 7.2 and 8.0 by @galathius and @dependabot in https://github.com/toptal/granite/pull/144

## v0.17.4

* Undeprecate the `Granite::Action#perform` method.

## v0.17.3

* Stopped preconditions from being executed twice on `#try_perform!`

## v0.17.2

* Deprecate `Granite::Action#perform` in favor of using `Granite::Action#try_perform!`, as these 2 methods are basically identical. It will be removed in next major version. (https://github.com/toptal/granite/pull/117)

## v0.17.1

* Fix in_transaction collisions with other gems (https://github.com/toptal/granite/pull/112)

## v0.17.0

* Support for ruby 3.2 by @konalegi in https://github.com/toptal/granite/pull/100
* Refine main page of the Granite docs by @jarosluv in https://github.com/toptal/granite/pull/101
* Refine documentation. Part 2 by @jarosluv in https://github.com/toptal/granite/pull/103
* Support for Rails 7.1 by @ojab and @dependabot in https://github.com/toptal/granite/pull/107
* [BREAKING] Drop support for Rails < 6.0 by @ojab and @dependabot in https://github.com/toptal/granite/pull/107

## v0.16.0

* Add `after_initialize` callback.
* Fix `after_commit` being called even if `perform` fails (because of failing preconditions/validations).
* Extract `Granite::Util` to `granite-form`. It's now called `Granite::Form::Util`.
* [BREAKING] Change granite projector specs to use controller specs instead of request specs:
  * This means that you'll have to replace `get projector.action_path` with `get :action`.
  * As a temporary measure you should be able to `include RSpec::Rails::RequestExampleGroup` in your describe block to use request specs temporarily. This is not guaranteed to not break in the future.

## v0.15.1

* Remove `BA` prefix in granite action generator
* Remove automatic synchronization from `embeds_many`/`embeds_one` associated objects (`action.association`) to their appropriate virtual attribute (`action.attributes('association')`)
* Update minimum granite-form version to 0.3.0

## v0.15.0

* [BREAKING] Change form builder from ActiveData to Granite::Form. This means Granite no longer depends
  on ActiveData, Granite::Form currently is a direct replacement for ActiveData that uses same syntax.
* Add support for detecting types of aliased attributes when using `represents`

## v0.14.2

* Fix error existence check on `Granite::Action#merge_errors` in Rails 6.1
* Add `Granite::Action.subject?` helper method
* Fix ActiveRecord::Enum handling with represents

## v0.14.1

* Introduce the ruby2_keywords (https://github.com/ruby/ruby2_keywords) gem in order
  to provide compatibility with Ruby 3 for some internal methods

## v0.14.0

* Introduce instrumentation and RSpec matcher to check if action was performed:
  https://toptal.github.io/granite/testing/#testing-composition
* Introduce `Action.with` as a more powerful replacement for `Action.as`, that allows passing more than
  just performer: https://toptal.github.io/granite/#context-performer

## v0.13.0

* Fix Ruby 3 Warnings
* Improve how projector specs initialize controller to be more rails like and fix several issues.
  * [BREAKING] As a result abstract actions/projectors will have to be initialized using `prepend_before` in projector specs.

## v0.12.1

* Fix parameterized precondition error messages not working in Ruby 3.

## v0.12.0

* Support for Rails 6.1 (via https://github.com/toptal/active_data fork)
* Support for Rails 7.0
* Fix `represents` with `default: false` not seeing any changes in model

## v0.11.1

* Make `assign_data` protected so that it can be called from other actions.

## v0.11.0

* [BREAKING] Implemented `assign_data`, which replaces `before_validation` as a way to set data for models before validations.
* Converted `represents` to use `assign_data`
* Fix dispatcher not working correctly with blank routes (e.g. `post :perform, as: ''`)

## v0.10.0

* Fix Ruby 2.7 and 3.0 compatibility issues

## v0.9.9

* Simplify translations code when expanding relative keys (`.key`)
* Fix one Ruby 3 incompatibility

## v0.9.8

* Extract `Granite::Util` which allows evaluating conditions

## v0.9.7

* fix `represents` to skip not defined attributes on the reference

## v0.9.6

* fix gemspec to include `config` directory
* update readme

## v0.9.5

* add rubocop config that can be included in projects using Granite

## v0.9.4

* fix documentation
* add Rails 6 support
* fix path helper to work with string arguments

## v0.9.3

* move `apply_association_changes!` to perform block

## v0.9.2

* `satisfy_preconditions` matcher supports composable matchers.

## v0.9.1

### Changes

* `satisfy_preconditions` matcher supports regular expressions

### Bug fixes

* remove callback loop triggered by executing action in `after_commit` of another action

## v0.9.0

### Breaking Changes

* nested executions of actions creates a proper nested transactions using `ActiveRecord::Base.transaction(requires_new: true)`. [See how it works at Nested Transaction section](https://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html)

* don't silence `Granite::Action::Rollback` error when there is no `ActiveRecord`

### Changes

* introduced `after_commit` callback for actions

## v0.8.3

### Breaking Changes

* `represents` attribute with a default value updates corresponding model's attribute even when action's attribute was not changed

* represented value of model goes through defaultize and typecaster

## v0.8.0

### Changes

* `represents` supports `allow_nil` option

## v0.7.0

In the beginning was the Word, and the Word was **Granite**
