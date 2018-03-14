# Book creation

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

### Perform

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
