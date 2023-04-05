# Testing

Granite provides several RSpec helpers for testing your application. To use them, add `require 'granite/rspec'` to your `rails_helper.rb` file.

All specs that live in `spec/apq/actions/` will get tagged with `:granite_action` type and will have access to Granite action specific helpers.

All specs that live in `spec/apq/projectors/` will get tagged with `:granite_projector` type and will have access to Granite projector specific helpers.

## Subject

The subject is an instance of the action being tested. You can create it using the `as` method to specify the performer, and passing any necessary attributes as arguments. Here's an example:

```ruby
subject(:action) { described_class.as(performer).new(user, attributes) }
let(:user) { User.new }
let(:attributes) { {} }
```

## Projectors

You can test your projectors using the `have_projector` matcher. Here's an example:

```ruby
it { is_expected.to have_projector(:simple) }
```

You can also test overridden projector methods like this:

```ruby
describe 'projectors', type: :granite_projector do
  subject { action.modal }
  projector { described_class.modal }

  it { expect(projector.perform_success_response).to eq(my_success: 'yes') }
end
```

If you need to test controller methods, you can do so like this:

```ruby
describe 'projectors', type: :granite_projector do
  projector { described_class.modal }
  before { get :confirm, params: attributes }
  it { expect(response).to be_successful }
end
```

To test projectors, you can define a abstract action class and use it to test the projector like this:

```ruby
describe SimpleProjector do
  let(:dummy_action_class) do
    Class.new BaseAction do
      projector :simple
    end
  end
  
  prepend_before do
    stub_const('DummyAction', dummy_action_class)
  end
  
  projector { DummyAction.simple }
  
  it { expect(projector.some_method).to eq('some_result') }
end
```

## Policies

You can test action policies using the `be_allowed` matcher like this:

```ruby
subject { described_class.as(User.new).new }
it { is_expected.to be_allowed }
```

## Preconditions

You can test action preconditions using the `satisfy_preconditions` matcher. Here's an example:

```ruby
context 'correct initial state' do
  it { is_expected.to satisfy_preconditions }
end

context 'incorrect initial state' do
  let(:company) { build_stubbed(:company, :active) }
  it { is_expected.not_to satisfy_preconditions.with_message("Some validation message") }
  it { is_expected.not_to satisfy_preconditions.with_messages(["First validation message", "Second validation message"]) }
end
```

## Validations

Validations tests are no different to Active Record models tests.

## Performing

You can use the `perform!` method to run the action and test its side-effects like this:

```ruby
specify { expect { perform! }.to change(User, :count).by(1) }
```

### Testing action is performed from another action

You can test that an action is performed from another action using the `perform_action` matcher. Here's an example:

```ruby
it { expect { perform! }.to perform_action(MyAction) }
it { expect { perform! }.to perform_action(MyAction).as(performer).with(user: user).using(:try_perform!) }
```
