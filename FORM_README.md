[![Build Status](https://travis-ci.org/toptal/granite-form.png?branch=master)](https://travis-ci.org/toptal/granite-form)
[![Code Climate](https://codeclimate.com/github/toptal/granite-form.png)](https://codeclimate.com/github/toptal/granite-form)

# Granite::Form

`Granite::Form` is an `ActiveModel`-based front-end for your data. It is useful in the following cases:

* When you need a form objects pattern.

```ruby
class ProfileForm
  include Granite::Form::Model

  attribute 'first_name', String
  attribute 'last_name', String
  attribute 'birth_date', Date

  def full_name
    [first_name, last_name].reject(&:blank).join(' ')
  end

  def full_name= value
    self.first_name, self.last_name = value.split(' ', 2).map(&:strip)
  end
end

class ProfileController < ApplicationController
  def edit
    @form = ProfileForm.new current_user.attributes
  end

  def update
    result = ProfileForm.new(params[:profile_form]).save do |form|
      current_user.update_attributes(form.attributes)
    end

    if result
      redirect_to ...
    else
      render 'edit'
    end
  end
end
```

* When you need to work with data storage à la `ActiveRecord`.

```ruby
class Flight
  include Granite::Form::Model

  attribute :airline, String
  attribute :number, String
  attribute :departure, Time
  attribute :arrival, Time

  validates :airline, :number, presence: true

  def id
    [airline, number].join('-')
  end

  def self.find id
    source = REDIS.get(id)
    instantiate(JSON.parse(source)) if source.present?
  end

  define_save do
    REDIS.set(id, attributes.to_json)
  end

  define_destroy do
    REDIS.del(id)
  end
end
```

* When you need to embed objects in `ActiveRecord` models.

```ruby
class Answer
  include Granite::Form::Model

  attribute :question_id, Integer
  attribute :content, String

  validates :question_id, :content, presence: true
end

class Quiz < ActiveRecord::Base
  embeds_many :answers

  validates :user_id, presence: true
  validates :answers, associated: true
end

quiz = Quiz.new
quiz.answers.build(question_id: 42, content: 'blabla')
quiz.save
```

## Why?

`Granite::Form` is an `ActiveModel-based library that provides the following functionalities:

  * Standard form objects building toolkit: attributes with typecasting, validations, etc.
  * High-level universal ORM/ODM library using any data source (DB, http, redis, text files).
  * Embedding objects into ActiveRecord entities. Quite useful with PG JSON capabilities.

Key features:

  * Complete object lifecycle support: saving, updating, destroying.
  * Embedded and referenced associations.
  * Backend-agnostic named scopes.
  * Callbacks, validations and dirty attributes.

## Installation

Add this line to your application's Gemfile:

    gem 'granite-form'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install granite-form

## Usage

`Granite::Form` has modular architecture, so it is required to include modules to obtain additional features. By default `Granite::Form` supports attributes definition and validations.

### Attributes

`Granite::Form` provides several types of attributes and typecasts each attribute to its defined type upon initialization.

```ruby
class Book
  include Granite::Form::Model

  attribute :title, String
  collection :author_ids, Integer
end
```

#### Attribute

```ruby
attribute :full_name, String, default: 'John Talbot'
```

If type for an attribute is not set, it defaults to `Object`. It is therefore recommended to specify the type for every attribute explicitly.

The type is necessary for attribute typecasting. Here is the list of pre-defined basic typecasters:

```irb
[1] pry(main)> Granite::Form._typecasters.keys
=> ["Object", "String", "Array", "Hash", "Date", "DateTime", "Time", "ActiveSupport::TimeZone", "BigDecimal", "Float", "Integer", "Boolean", "Granite::Form::UUID"]
```

In addition, you can provide any class type when defining an attribute, but in that case you will be able to only assign instances of that specific class or `nil`:

```ruby
attribute :template, MyCustomTemplateType
```

##### Defaults

It is possible to provide default values for attributes and they will act in the same way as `ActiveRecord` or `Mongoid` default values:

```ruby
attribute :check, Boolean, default: false # Simply false by default
attribute :wday, Integer, default: ->{ today.wday } # Default evaluated in instance context
def calculate_today
  Time.zone.now.today
end
```

##### Enums

Enums restrict the scope of possible values for an attribute. If the assigned value is not included in the provided list, the attribute value is set to `nil`:

```ruby
attribute :direction, String, enum: %w[north south east west]
```

##### Normalizers

Normalizers are applied last, modifying a typecast value. It is possible to provide a list of normalizers. They will be applied in the provided order. It is possible to pre-define normalizers to DRY code:

```ruby
Granite::Form.normalizer(:trim) do |value, options, _attribute|
  value.first(options[:length] || 2)
end

attribute :title, String, normalizers: [->(value) { value.strip }, trim: {length: 80}]
```

##### Readonly

```ruby
attribute :name, String, readonly: true # Readonly forever
attribute :name, String, readonly: :name_changed? # Conditional with calling method
attribute :name, String, readonly: -> { subject.present? } # Conditional with lambda
```

#### Collection

A collection is simply an array of equally-typed values:

```ruby
class Panda
  include Granite::Form::Model

  collection :ids, Integer
end
```

A collection typecasts each value to the specified type. Also, it normalizes any given value to an array.

```irb
[1] pry(main)> Panda.new
=> #<Panda ids: []>
[2] pry(main)> Panda.new(ids: 42)
=> #<Panda ids: [42]>
[3] pry(main)> Panda.new(ids: [42, '33'])
=> #<Panda ids: [42, 33]>
```

Default and enum modifiers are applied on each value, normalizers are applied on the array.

#### Dictionary

A dictionary field is a hash of specified type values with string keys:

```ruby
class Foo
  include Granite::Form::Model

  dictionary :ordering, String
end
```

```irb
[1] pry(main)> Foo.new
=> #<Foo ordering: {}>
[2] pry(main)> Foo.new(ordering: {name: :desc})
=> #<Foo ordering: {"name"=>"desc"}>
```

The keys list might be restricted with the `:keys` option. Default and enum modifiers are applied on each value, normalizers are applied on the hash.

#### Represents

`represents` provides an easy way to expose model attributes through an interface.
It will automatically set the passed value to the represented object **before validation**.
You can use any `ActiveRecord`, `ActiveModel` or `Granite::Form` object as a target of representation.
The type of an attribute will be taken from it.
If no type is defined, it will be `Object` by default. You can set the type explicitly by passing the `type: TypeClass` option.
Represents will also add automatic validation of the target object.

```ruby
class Person
  include Granite::Form::Model

  attribute :name, String
end

class Doctor
  include Granite::Form::Model
  include Granite::Form::Model::Representation

  attribute :person, Object
  represents :name, of: :person
end

person = Person.new(name: 'Walter Bishop')
# => #<Person name: "Walter Bishop">
Doctor.new(person: person).name
# => "Walter Bishop"
Doctor.new(person: person, name: 'Dr. Walter Bishop').name
# => "Dr. Walter Bishop"
person.name
# => "Dr. Walter Bishop"
```

### Associations

`Granite::Form` provides a set of associations. There are two types: referenced and embedded. The closest example of referenced association is `AcitveRecord`'s `belongs_to`. For embedded ones - Mongoid's embedded. Also these associations support `accepts_nested_attributes` calls.

#### EmbedsOne

```ruby
embeds_one :profile
```

Defines singular embedded object. Might be defined inline:

```ruby
embeds_one :profile do
  attribute :first_name, String
  attribute :last_name, String
end
```

Оptions:

* `:class_name` - association class name
* `:validate` - `true` or `false`
* `:default` - default value for the association: an attributes hash or an instance of the defined class

#### EmbedsMany

```ruby
embeds_many :tags
```

Defines a collection of embedded objects. Might be defined inline:

```ruby
embeds_many :tags do
  attribute :identifier, String
end
```

Оptions:

* `:class_name` - association class name
* `:validate` -  `true` or `false`
* `:default` - default value for the association: an attributes hash or an instance of the defined class

#### ReferencesOne

```ruby
references_one :user
```

Provides several methods to the object: `#user`, `#user=`, `#user_id` and `#user_id=`, similarly to an ActiveRecord association.

Оptions:

* `:class_name` - association class name
* `:primary_key` - the associated object's primary key name (`:id` by default):

  ```ruby
  references_one :user, primary_key: :name
  ```

  Creates the following methods: `#user`, `#user=`, `#user_name` and `#user_name=`.

* `:reference_key` - redefines `#user_id` and `#user_id=` method names completely.
* `:validate` - `true` or `false`
* `:default` - default value for the association: reference or the object itself

#### ReferencesMany

```ruby
references_many :users
```

Provides several methods to the object: `#users`, `#users=`, `#user_ids` and `#user_ids=`, similarly to an ActiveRecord association.

Options:

* `:class_name` - association class name
* `:primary_key` - the associated object's primary key name (`:id` by default):

  ```ruby
  references_many :users, primary_key: :name
  ```

  Creates the following methods: `#users`, `#users=`, `#user_names` and `#user_names=`.

* `:reference_key` - redefines `#user_ids` and `#user_ids=` method names completely.
* `:validate` - true or false
* `:default` - default value for association: reference collection or objects themselves

### Persistence Adapters

Adapter definition syntax:
```ruby
class Mongoid::Document
  # anything that have similar interface to
  # Granite::Form::Model::Associations::PersistenceAdapters::Base
  def self.granite_persistence_adapter
    MongoidAdapter
  end
end
```
where
`ClassName` - name of model class or one of ancestors
`data_source` - name of data source class
`primary_key` - key to search data
`scope_proc` - additional proc for filtering

All requirements for the adapter interfaces are described in `Granite::Form::Model::Associations::PersistenceAdapters::Base`.

The adapter for `ActiveRecord` is `Granite::Form::Model::Associations::PersistenceAdapters::ActiveRecord`. All `ActiveRecord` models use `PersistenceAdapters::ActiveRecord` by default.

### Primary

### Persistence

### Lifecycle

### Callbacks

### Dirty

### Validations

### Scopes

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
