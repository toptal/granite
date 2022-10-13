# master (not released yet)

# Version 0.14.2

* Fix error existence check on `Granite::Action#merge_errors` in Rails 6.1
* Add `Granite::Action.subject?` helper method
* Fix ActiveRecord::Enum handling with represents

# Version 0.14.1

* Introduce the ruby2_keywords (https://github.com/ruby/ruby2_keywords) gem in order
  to provide compatibility with Ruby 3 for some internal methods

# Version 0.14.0

* Introduce instrumentation and RSpec matcher to check if action was performed:
  https://toptal.github.io/granite/testing/#testing-composition
* Introduce `Action.with` as a more powerful replacement for `Action.as`, that allows passing more than
  just performer: https://toptal.github.io/granite/#context-performer

# Version 0.13.0

* Fix Ruby 3 Warnings
* Improve how projector specs initialize controller to be more rails like and fix several issues.
  * [BREAKING] As a result abstract actions/projectors will have to be initialized using `prepend_before` in projector specs.

# Version 0.12.1

* Fix parameterized precondition error messages not working in Ruby 3.

# Version 0.12.0

* Support for Rails 6.1 (via https://github.com/toptal/active_data fork)
* Support for Rails 7.0
* Fix `represents` with `default: false` not seeing any changes in model

# Version 0.11.1

* Make `assign_data` protected so that it can be called from other actions.

# Version 0.11.0

* [BREAKING] Implemented `assign_data`, which replaces `before_validation` as a way to set data for models before validations.
* Converted `represents` to use `assign_data`
* Fix dispatcher not working correctly with blank routes (e.g. `post :perform, as: ''`)

# Version 0.10.0

* Fix Ruby 2.7 and 3.0 compatibility issues

# Version 0.9.9

* Simplify translations code when expanding relative keys (`.key`)
* Fix one Ruby 3 incompatibility

# Version 0.9.8

* Extract `Granite::Util` which allows evaluating conditions

# Version 0.9.7

* fix `represents` to skip not defined attributes on the reference

# Version 0.9.6

* fix gemspec to include `config` directory
* update readme

# Version 0.9.5

* add rubocop config that can be included in projects using Granite

# Version 0.9.4

* fix documentation
* add Rails 6 support
* fix path helper to work with string arguments

# Version 0.9.3

* move `apply_association_changes!` to perform block

# Version 0.9.2

* `satisfy_preconditions` matcher supports composable matchers.

# Version 0.9.1

## Changes

* `satisfy_preconditions` matcher supports regular expressions

## Bug fixes

* remove callback loop triggered by executing action in `after_commit` of another action

# Version 0.9.0

## Breaking Changes

* nested executions of actions creates a proper nested transactions using `ActiveRecord::Base.transaction(requires_new: true)`. [See how it works at Nested Transaction section](https://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html)

* don't silence `Granite::Action::Rollback` error when there is no `ActiveRecord`

## Changes

* introduced `after_commit` callback for actions

# Version 0.8.3

## Breaking Changes

* `represents` attribute with a default value updates corresponding model's attribute even when action's attribute was not changed

* represented value of model goes through defaultize and typecaster

# Version 0.8.0

## Changes

* `represents` supports `allow_nil` option

# Version 0.7.0

In the beginning was the Word, and the Word was **Granite**
