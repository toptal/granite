# Applicatin example

The business we're going to cover is very simple.

We have a simple book library and we need to allow logged users to create new
books and rent it.

## Book library

A symple system to track books. Each book has a title.

- The books view is public
- **Only** logged users can edit the books
- Logged users can **edit** or **remove** a book

### The Rental system

- All available books can be **rented**
- Logged users can rent a book
- A book is not **available** when it's rented to someone
- A book is **available** after it's delivered back

### Books wishlist

The logged user can manage a **wishlist** considering:

- When a book is **not available** and the user "**didn't read** it
- If the person **already read** the book, also **doesn't make sense add it in the wishlist
- When the book become available, the system should notify people that are with this book in the wishlist
- When the book is rented by someone that have the book in the wishlist, it should be removed after delivered back

The application domain is very simple and we're going to build step by step
this small logic case to show how granite can be useful and abstract a few
steps of your application.

## New project setup

We're testing here with Rails version x. The following example can be found
here: https://github.com/toptal/example_granite_application

### Generating new project

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

## Setup devise

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

## Setup granite

Add `granite` to your Gemfile:

```ruby
gem 'granite'
```

And `bundle install` again.

Add `require 'granite/rspec'` to your `rails_helper.rb`. Check more details on
the [testing](testing.md) section.

!!! warning
    If you get in any trouble in this section, please
    [report an issue](https://github.com/toptal/granite/issues/new).

## Book::Create

It's time to create our first model and have some initial domain on it.

Let's use a scaffold to have a starting point with the `Book` model:

```bash
rails g scaffold book title:string
```

Now, we can start working in the first business action.

Let's generate the boilerplate business action class with Rails granite generator:

```ruby
rails g granite book/create
```

The following classes was generated:

```ruby
# apq/actions/ba/book/create.rb
class BA::Book::Create < BA::Book::BusinessAction
  allow_if { false }

  precondition do
  end

  private

  def execute_perform!(*)
    subject.save!
  end
end
```

And also a default business action was added with the shared subject:

```
class BA::Book::BusinessAction < BaseAction
  subject :book
end
```

## Policies

The generated code says `allow_if { false }` and we need to restrict it to
logged users. Let's replace this line to restrict the action only for logged users:

```ruby
# apq/actions/ba/book/create.rb
class BA::Book::Create < BA::Book::BusinessAction
  allow_if { performer.is_a?(User) }
  # ...
end
```

And let's start testing it:

```ruby
require 'rails_helper'
RSpec.describe BA::Book::Create do
  subject(:action) { described_class.as(performer).new }
  let(:performer) { User.new }

  describe 'policies' do
    it { is_expected.to be_allowed }

    context 'when user is not authorized' do
      let(:performer) { double }
      it { is_expected.not_to be_allowed }
    end
  end
end
```


## Attributes

We also need to be specific of what attributes this action can touch and then
we need to define attributes for it:

```ruby
# apq/actions/ba/book/create.rb
class BA::Book::Create < BA::Book::BusinessAction
  # ...
  represents :title, of: :subject
  # ...
end
```

We can define some validations to not allow try to save without specify a
title:

```ruby
# apq/actions/ba/book/create.rb
class BA::Book::Create < BA::Book::BusinessAction
  # ...
  validates :title, presence: true
  # ...
end
```

And now we can properly test it:

```ruby
require 'rails_helper'

RSpec.describe BA::Book::Create do
  subject(:action) { described_class.as(performer).new(attributes) }

  let(:performer) { User.new }
  let(:attributes) { { 'title' => 'Ruby Pickaxe'} }

  describe 'policies' do
    it { is_expected.to be_allowed }

    context 'when user is not authorized' do
      let(:performer) { double }
      it { is_expected.not_to be_allowed }
    end
  end

  describe 'validations' do
    it { is_expected.to be_valid }

    context 'when preconditions fail' do
      let(:attributes) { { } }
      it { is_expected.not_to be_valid }
    end
  end
end
```

## Perform

For now, the perform is a simple call to `book.save!` because granite already
assign the attributes.

Then we need to test if it's generating the right record:

```ruby
require 'rails_helper'

RSpec.describe BA::Book::Create do
  subject(:action) { described_class.as(performer).new(attributes) }

  let(:performer) { User.new }
  let(:attributes) { { 'title' => 'Ruby Pickaxe'} }

  # describe 'policies' ...
  # describe 'validations' ...

  describe '#perform!' do
    specify do
      expect { action.perform! }.to change { Book.count }.by(1)
      expect(action.subject.attributes.except('id', 'created_at', 'updated_at')).to eq(attributes)
    end
  end
end
```

## Book::Rent

The Rental system description says:

- All available books can be **rented**
- Logged users can rent a book
- A book is not **available** when it's rented to someone
- A book is **available** after it's delivered back

So, what we're going to do is:

1. Generate migration to create the rental table referencing the book and the user
2. Add an `available` boolean column in the books table
3. Create a business action `Book::Rent` and test the conditions above

Let's create `Rent` model first:

```bash
rails g model rent book:references user:references delivered_back_at:timestamp
```

and add available column in the books table:

```bash
rails g migration add_availability_to_books available:boolean
```

Now it's time to generate the next granite action:

```bash
rails g granite book/rent
```

## Preconditions

Let's write specs for the preconditions first:

```ruby
RSpec.describe BA::Book::Rent do
  subject(:action) { described_class.as(performer).new(book) }

  let(:performer) { User.new }

  let(:book) { Book.new(title: 'First book', available: available) }

  describe 'preconditions' do
    context 'with available book' do
      let(:available) { true }
      it { is_expected.to be_satisfy_preconditions }
    end

    context 'with unavailable book' do
      let(:available) { false }
      it { is_expected.to be_invalid }
      it { is_expected.not_to satisfy_preconditions }
    end
  end
end
```

[Preconditions](/granite/#preconditions) are related to the book in the context.
And the action will decline the context to not be executed if it does not satisfy the preconditions.

Let's implement the `precondition` and `perform` code:

```ruby
class BA::Book::Rent < BA::Book::BusinessAction
  precondition { book.available? }

  private

  def execute_perform!(*)
    Rent.create!(book: subject, user: performer)
    subject.available = false
    subject.save!
  end
end
```

Now, let's cover the perform with another spec:

```ruby
RSpec.describe BA::Book::Rent do
  subject(:action) { described_class.as(performer).new(book) }

  let(:performer) { User.new }

  let(:book) { Book.new(title: 'First book', available: available) }

  # describe 'preconditions' ...

  describe '#perform!' do
    specify do
      expect { action.perform! }
        .to change(book, :available).from(true).to(false)
        .and change(Rent, :count).by(1)
    end
  end
end
```

## Book::DeliverBack

To deliver back a book, it need to be rented by the person that is logged in.

Then we need to have a precondition to verify if the current book is being
rented by this person:

```ruby
class BA::Book::DeliverBack < BA::Book::BusinessAction
  precondition do
    rental_conditions = { book: subject, user: performer, delivered_back_at: nil }
    Rent.where(rental_conditions).exists?
  end
end
```

The logic of the deliver back, we just need to pick the current rental and
assign the `delivered_back_at` date. Also, make the book available again.

```ruby
class BA::Book::DeliverBack < BA::Book::BusinessAction
  precondition do
    Rent.where(rental_conditions).exists?
  end

  private

  def execute_perform!(*)
    rent.delivered_back_at = Time.now
    rent.save!

    subject.available = true
    subject.save!
  end

  def rent
    @rent ||= Rent.find_by(rental_conditions)
  end

  def rental_conditions
    { book: subject, user: performer, delivered_back_at: nil }
  end
end
```

## Wishlist::Add

## Wishlist::Remove

## Wishlist::NotifyAvailability

