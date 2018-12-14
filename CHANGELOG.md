# master (not released yet)

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
