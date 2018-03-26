# Application example

The business we're going to cover is straightforward.
It will be a book library, and we need to allow logged in users to create new
books and rent it.

## Book library

A simple system to track books. Each book has a title.

- Everybody can view the list of books
- **Only** logged in users can edit the books
- Logged in users can **edit** or **remove** a book

### The Rental system

- All available books can be **rented**
- Logged in users can rent a book
- A book is not **available** when it's rented to someone
- A book is **available** after return

### Books wishlist

The logged in user can manage a **wishlist** considering:

- When a book is **not available** and the user **didn't read** it
- If the person **already read** the book, also **doesn't make sense add it to the wishlist**
- When the book becomes available, the system should notify people that are with this book on the wishlist
- When the book is rented by someone that has the book on the wishlist, it should be removed after return

The application domain is very simple, and we're going to build step by step
this small logic case to show how granite can be useful and abstract a few
steps of your application.

## New project setup

We're testing here with Rails version x. The following example can be found
here: https://github.com/toptal/example_granite_application

### Generating a new project

This tutorial is using Rails version `5.1.4`, and the first step is to install it:

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

Let's add devise to control users access and have a simple control over logged
users. Adding it to `Gemfile`.

```ruby
gem 'devise'
```

Run `bundle install` and then generate the default devise resources.

```bash
rails generate devise:install
```

And then, let's create a simple devise model to interact with:

```bash
rails generate devise user
```

And migrate again:

```bash
rails db:migrate
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

It's time to create our first model and has some domain on it.

Let's use a scaffold to have a starting point with the `Book` model:

```bash
rails g scaffold book title:string
```

Now, we can start working on the first business action.

Let's generate the boilerplate business action class with Rails granite generator:

```ruby
rails g granite book/create
```

The following class was generated:

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

Additionally, a "base", shared class is generated, that defines the subject
type for all the inherited classes in the namespace Book.

```
class BA::Book::BusinessAction < BaseAction
  subject :book
end
```

## Policies

The generated code says `allow_if { false }` and we need to restrict it to
logged in users. Let's replace this line to restrict the action only for logged in users:

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

    context 'when the user is not authorized' do
      let(:performer) { double }
      it { is_expected.not_to be_allowed }
    end
  end
end
```

## Attributes

We also need to be specific about what attributes this action can touch and then
we need to define attributes for it:

```ruby
# apq/actions/ba/book/create.rb
class BA::Book::Create < BA::Book::BusinessAction
  # ...
  represents :title, of: :subject
  # ...
end
```

We can define some validations to not allow saving without specifying a title:

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

    context 'when the user is not authorized' do
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

For now, the perform is a simple call to `book.save!` because Granite already
assign the attributes.

Then we need to test if it's generating the right record:

```diff
require 'rails_helper'

RSpec.describe BA::Book::Create do
  subject(:action) { described_class.as(performer).new(attributes) }

  let(:performer) { User.new }
  let(:attributes) { { 'title' => 'Ruby Pickaxe'} }

  describe 'policies' do
    it { is_expected.to be_allowed }

    context 'when the user is not authorized' do
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

+   describe '#perform!' do
+     specify do
+       expect { action.perform! }.to change { Book.count }.by(1)
+       expect(action.subject.attributes.except('id', 'created_at', 'updated_at')).to eq(attributes)
+     end
+   end
end
```

The last step is to replace the current book creation in the controller to call
the business action instead.

First thing is rescue from `Granite::NotAllowed` when some action is not allowed
to be executed.

```ruby
class BooksController < ApplicationController
  rescue_from Granite::Action::NotAllowedError do |exception|
    redirect_to books_path, alert: "You're not allowed to execute this action."
  end
  # ...
end
```

It will generically manage exceptions in case some unauthorized user tries to force acting without having access.

The next step is to wrap the method `#create` with the proper business action call.

```ruby
class BooksController < ApplicationController

  # ...

  # POST /books
  def create
    book_action = BA::Book::Create.as(current_user).new(book_params)
      if book_action.perform
        redirect_to book_action.subject, notice: 'Book was successfully created.'
      else
        @book = book_action.subject
        render :new
      end
    end
  end

  # ...
end
```

## Book::Rent

To start renting the book, we need a few steps:

1. Generate migration to create the rental table referencing the book and the user
2. Add an `available` boolean column in the books table
3. Create a business action `Book::Rent` and test the conditions above

Let's create `Rental` model first:

```bash
rails g model rental book:references user:references returned_at:timestamp
```

and add an `available` column in the books table:

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
    context 'with an available book' do
      let(:available) { true }
      it { is_expected.to be_satisfy_preconditions }
    end

    context 'with an unavailable book' do
      let(:available) { false }
      it { is_expected.to be_invalid }
      it { is_expected.not_to satisfy_preconditions }
    end
  end
end
```

[Preconditions](/granite/#preconditions) are related to the book in the context.
And the action will decline the context not to be executed if it does not satisfy the preconditions.

Let's implement the `precondition` and `perform` code:

```diff
class BA::Book::Rent < BA::Book::BusinessAction
+ precondition { book.available? }

  private

  def execute_perform!(*)
    Rental.create!(book: subject, user: performer)
    subject.available = false
    subject.save!
  end
end
```

Now, let's cover the perform with another spec:

```diff
RSpec.describe BA::Book::Rent do
  subject(:action) { described_class.as(performer).new(book) }

  let(:performer) { User.new }

  let(:book) { Book.new(title: 'First book', available: available) }

+ describe 'preconditions' do
+   context 'with an available book' do
+     let(:available) { true }
+     it { is_expected.to be_satisfy_preconditions }
+   end
+
+   context 'with an unavailable book' do
+     let(:available) { false }
+     it { is_expected.to be_invalid }
+     it { is_expected.not_to satisfy_preconditions }
+   end
+ end

  describe '#perform!' do
    specify do
      expect { action.perform! }
        .to change(book, :available).from(true).to(false)
        .and change(Rental, :count).by(1)
    end
  end
end
```

## Book::Return

First, think about the policies: to return the book, it needs to be rented by the person that is logged in.

Then we need to have a precondition to verify if the current book is being
rented by this person:

```ruby
class BA::Book::Return < BA::Book::BusinessAction
  precondition do
    rental_conditions = { book: subject, user: performer, returned_at: nil }
    Rental.where(rental_conditions).exists?
  end
end
```

The logic of the return, we just need to pick the current rental and
assign the `returned_at` date. Also, make the book available again.

Let's start by testing the preconditions and guarantee that only the user that
rent the book can return it.

```ruby
RSpec.describe BA::Book::Return do
  subject(:action) { described_class.as(performer).new(book) }

  let(:book) { Book.create! title: 'Learn to fly', available: true }
  let(:performer) { User.create! }

  describe 'preconditions' do
    context 'when the user rented the book' do
      before { BA::Book::Rent.as(performer).new(book).perform! }
      it { is_expected.to be_satisfy_preconditions }
    end

    context 'when preconditions fail' do
      it { is_expected.not_to be_satisfy_preconditions }
    end
  end
end
```

And implementing the preconditions:


```ruby
class BA::Book::Return < BA::Book::BusinessAction

  subject :book
  allow_if { performer.is_a?(User) }

  precondition do
    decline_with(:not_renting) unless performer.renting?(book)
  end
end
```

And the `User` now have a few scopes and the `#renting?` method:

```ruby
class User < ApplicationRecord
  devise :database_authenticatable, :registerable
  has_many :rentals
  has_many :books, through: :rentals

  def renting?(book)
    rentals.current.where(book: book).exists?
  end
end
```

Now implementing the spec that covers the logic of return, is expected to
make the book available and mark the rental with the given date.

```diff
RSpec.describe BA::Book::Return do
  subject(:action) { described_class.as(performer).new(book) }

  let(:book) { Book.create! title: 'Learn to fly', available: true }
  let(:performer) { User.create! }

  describe 'preconditions' do
    context 'when the user rented the book' do
      before { BA::Book::Rent.as(performer).new(book).perform! }
      it { is_expected.to be_satisfy_preconditions }
    end

    context 'when preconditions fail' do
      it { is_expected.not_to be_satisfy_preconditions }
    end
  end

+   describe '#perform!' do
+     let!(:rental) { Rental.create! book: book, user: performer }
+ 
+     specify do
+       expect { action.perform! }
+         .to change { book.reload.available }.from(false).to(true)
+         .and change { rental.reload.returned_at }.from(nil)
+     end
+   end
end
```

## I18n

The last step to make it user-friendly and return a personalized
message when the business action calls `decline_with(:unavailable)`.

It's time to create the internationalization file for it.

File: `config/locales/granite.en.yml`
```yml
en:
  granite_action:
    errors:
      models:
        ba/book/rent:
          attributes:
            base:
              unavailable: 'The book is unavailable.'
```

Great! Now it's time to change our views to allow people to interact with the
actions we created.

First, we need to add controller methods to call the `Rent` and `Return`
business actions and create routes for it.

```ruby
class BooksController < ApplicationController

  # a few other scaffold methods here

  # POST /books/1/rent
  def rent
    @book = Book.find(params[:book_id])
    book_action = BA::Book::Rent.as(current_user).new(@book)
    if book_action.perform
      redirect_to books_url, notice: 'Enjoy the book!'
    else
      redirect_to books_url, alert:  book_action.errors.full_messages
    end
  end

  # POST /books/1/return_book
  def return_book
    @book = Book.find(params[:book_id])
    book_action = BA::Book::Return.as(current_user).new(@book)
      if book_action.perform
        redirect_to books_url, notice: 'Thanks for delivering it back.'
      else
        redirect_to books_url, alert:  book_action.errors.full_messages
      end
    end
  end
end
```

And add routes for `rent` and `return_book` in `config/routes.rb`:

```ruby
  resources :books do
    post :rent
    post :return_book
  end
```

Now, it's time to change the current view to add such actions:

```erb
  <tbody>
    <% @books.each do |book| %>
      <tr>
        <td><%= book.title %></td>
        <% if book.available? %>
          <td><%= link_to 'Rent', rent_book_path(book), method: :post %></td>
        <% else %>
          <td>(Rented)</td>
        <% end %>
        <% if current_user && current_user.renting?(book) %>
           <td><%= link_to 'Return', return_book_path(book), method: :post %></td>
        <% end %>
        <td><%= link_to 'Show', book %></td>
        <td><%= link_to 'Edit', edit_book_path(book) %></td>
        <td><%= link_to 'Destroy', book, method: :delete, data: { confirm: 'Do you really want to destroy this book?' } %></td>
      </tr>
    <% end %>
  </tbody>
```

Now is a good opportunity to introduce [projectors](projectors.md).

The actual implementation contains a few boilerplate code in the controller that make us repeat a
few different logics that are already in the business action.

Projectors can help with that. Avoiding the need for creating repetitive
controller methods and reverify preconditions and policies to decide what
actions can be executed.

### Setup view context for Granite projector

You'll need to set up the master controller class. Let's create a file to configure what will be the base controller for granite:

File: `config/initializers/granite.rb`
```ruby
Granite.tap do |m|
  m.base_controller = 'ApplicationController'
end
```

The next step is to change `ApplicationController` to setup context
view and allow granite to inherit behavior from it.

`app/controllers/application_controller`
```ruby
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  around_action :setup_granite_view_context
  before_action { view_context }

  protected
  def setup_granite_view_context(&block)
    Granite.with_view_context(view_context, &block)
  end
end
```

## Inline projector

The current `rent` and `returned_at` methods have a very similar structure.

And the projectors allows to declare the HTTP method like `get` or `post` and mount it in a route as an anonymous controller.

Inside the block, the action is already set with all parameters from the web
request and ready to be executed.

As the current controller actions are executed with `POST`, let's follow the same line and
create a simple projector that allows to receive some post data and redirect to the resources list back.

The projector will have a default `success_redirect` and `failure_redirect` after the action execution.
By default, let's assume that we'll redirect it to the collection and render a
positive notice or a negative alert to the previous action.

```ruby
class InlineProjector < Granite::Projector

  post :perform, as: '' do
    if action.perform!
      redirect_to projector.success_redirect, notice: t('.notice')
    else
      messages = projector.action.errors.full_messages.to_sentence
      redirect_to projector.failure_redirect, alert:  t('.error', messages)
    end
  end

  def collection_subject
    action.subject.class.name.downcase.pluralize
  end

  def success_redirect
    h.public_send("#{collection_subject}_path")
  end

  def build_action(*args)
    action_class.as(self.class.proxy_performer || h.current_user).new(*args)
  end
end
```

We also need to say who is the performer of the action.
The `build_action` method in the projector is implemented to override the
current performer in action with the `current_role`.

!!! info
    Note that `h` is an alias for `view_context` and you can access anything
    from the controller through it.

Now, it's time to say that we're going to use the projector inside the `Rent` action:

File: `apq/actions/ba/book/rent.rb`
```diff
class BA::Book::Rent < BaseAction
  subject :book

+  projector :inline

  allow_if { performer.is_a?(User) }

  precondition do
    decline_with(:unavailable) unless book.available?
  end

  private

  def execute_perform!(*)
    subject.available = false
    subject.save!
    Rental.create!(book: subject, user: performer)
  end
end
```

And also drop the method from the `BooksController`:

File: `app/controllers/books_controller.rb`
```diff
@@ -25,28 +25,6 @@ class BooksController < ApplicationController
     @book = Book.find(params[:id])
   end

-  # POST /books/1/rent
-  def rent
-    @book = Book.find(params[:book_id])
-    book_action = BA::Book::Rent.as(current_user).new(@book)
-    if book_action.perform
-      redirect_to books_url, notice: 'Book was successfully rented.'
-    else
-      redirect_to books_url, alert:  book_action.errors.full_messages.to_sentence
-    end
-  end
```

As the last step, we need to change the `config/routes.rb` to use the `granite`
to mount the `action#projector` into the defined routes.

File: `config/routes.rb`
```diff
Rails.application.routes.draw do
  root 'books#index'

  devise_for :users

  resources :books do
-   post :rent
+   granite 'BA/book/rent#inline'
    post 'return', to: 'books#return_book', as 'return'
  end
end
```

!!! warning
    As it's a tutorial, your next task is to do the same for `return_book`.

    1. Add `projector :inline` to `BA::Book::Return` class.
    2. Remove the controller method
    3. Refactor the `config/routes.rb` declaring the `granite 'action#projector'`


## Projector Helpers

You can define useful methods for helping you rendering your view and improving
the experience with your actions. Now, let's create a `button` function,
to replace the action links in the current list.

First, we need to have a method in our projector that can render the button if
the action is performable.

It will render nothing if the current user does not have access or it's an
anonymous session.

We'll render the action name stricken if the action is not performable with the
error messages in the title, because if people mouse over, they can see the
"tooltip" with why it's not possible to execute the action.

```ruby
class InlineProjector < Granite::Projector

  # ...
  # The previous methods remain here
  # ...

  def button(link_options = {})
    return unless action.allowed?
    if action.performable?
      h.link_to action_label, perform_path, method: :post
    end
  end

  def action_label
    action.class.name.demodulize.underscore.humanize
  end
end
```

And now, we can replace the links with the new `button` function:

```erb
  <tbody>
    <% @books.each do |book| %>
      <tr>
        <td><%= book.title %></td>
        <td><%= Ba::Book::Rent.as(current_user).new(book).inline.button%></td>
        <td><%= Ba::Book::Return.as(current_user).new(book).inline.button%></td>
        <td>... more links here ...</td>
      </tr>
    <% end %>
  </tbody>
```

Now it's clear, and the "Return" link will appear only for the user
that rented the book.


## Wishlist::Add

## Wishlist::Remove

## Wishlist::NotifyAvailability
