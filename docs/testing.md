# Testing

Granite has multiple helpers for your rspec tests. Add `require 'granite/rspec'` to your `rails_helper.rb` in order
to use them.
All specs that live in `spec/apq/actions/` will get tagged with `:granite_action` type and will have access to granite
action specific helpers.
All specs that live in `spec/apq/projectors/` will get tagged with `:granite_projector` type and will have access to
granite projector specific helpers.

<h3 id="testing-subject">Subject</h3>

```ruby
subject(:action) { described_class.as(performer).new(user, attributes) }
let(:user) { User.new }
let(:attributes) { {} }
```

<h3 id="testing-projectors">Projectors</h3>

```ruby
it { is_expected.to have_projector(:simple) }
```

Test overridden projector methods:

```ruby
describe 'projectors', type: :granite_projector do
  subject { action.modal }
  projector { described_class.modal }

  its(:perform_success_response) { is_expected.to eq(my_success: 'yes') }
end
```

<h3 id="testing-policies">Policies</h3>

```ruby
subject { described_class.as(User.new).new }
it { is_expected.to be_allowed }
```

<h3 id="testing-preconditions">Preconditions</h3>

```ruby
context 'correct initial state' do
  it { is_expected.to satisfy_preconditions }
end

context 'incorrect initial state' do
  let(:company) { build_stubbed(:company, :active) }
  it { is_expected.not_to satisfy_preconditions.with_message("Some validation message")}
  it { is_expected.not_to satisfy_preconditions.with_messages(["First validation message", "Second validation message"])}
end
```

<h3 id="testing-validations">Validations</h3>

Validations tests are no different to ActiveRecord models tests

<h3 id="testing-perform">Perform</h3>

Run the action using `perform!` to test side-effects:

```ruby
specify { expect { perform! }.to change(User, :count).by(1) }
```

