require 'spec_helper'

RSpec.describe Granite::Form::Model::Associations::Validations do
  before do
    stub_model(:project) do
      include Granite::Form::Model::Associations
      include Granite::Form::Model::Associations::Validations

      attribute :title, String
      validates :title, presence: true

      embeds_one :author do
        attribute :name, String
        validates :name, presence: true
      end
    end

    stub_model(:profile) do
      attribute :first_name, String
      attribute :last_name, String
      validates :first_name, presence: true
    end

    stub_model(:user) do
      include Granite::Form::Model::Associations
      include Granite::Form::Model::Associations::Validations

      attribute :login, String
      validates :login, presence: true

      embeds_one :profile, validate: false
      embeds_many :projects
    end
  end

  describe '#validate' do
    let(:profile) { Profile.new first_name: 'Name' }
    let(:project) { Project.new title: 'Project' }
    let(:projects) { [project] }
    let(:user) { User.new(login: 'Login', profile: profile, projects: projects) }
    let(:author_attributes) { { name: 'Author' } }

    before { project.build_author(author_attributes) }

    specify { expect(user.validate).to eq(true) }
    specify { expect { user.validate }.not_to(change { user.errors.messages }) }

    context do
      let(:author_attributes) { {} }

      specify { expect(user.validate).to eq(false) }

      specify do
        expect { user.validate }.to change { user.errors.messages }
          .to('projects.0.author.name': ["can't be blank"])
      end
    end

    context do
      let(:profile) { Profile.new }

      specify { expect(user.validate).to eq(true) }
      specify { expect { user.validate }.not_to(change { user.errors.messages }) }
    end

    context do
      let(:projects) { [project, Project.new] }

      specify { expect(user.validate).to eq(false) }

      specify do
        expect { user.validate }.to change { user.errors.messages }
          .to('projects.1.title': ["can't be blank"])
      end
    end
  end

  describe '#validate_ancestry, #valid_ancestry?, #invalid_ancestry?' do
    let(:profile) { Profile.new first_name: 'Name' }
    let(:project) { Project.new title: 'Project' }
    let(:projects) { [project] }
    let(:user) { User.new(login: 'Login', profile: profile, projects: projects) }
    let(:author_attributes) { { name: 'Author' } }

    before { project.build_author(author_attributes) }

    specify { expect(user.validate_ancestry).to eq(true) }
    specify { expect(user.validate_ancestry!).to eq(true) }
    specify { expect { user.validate_ancestry! }.not_to raise_error }
    specify { expect(user.valid_ancestry?).to eq(true) }
    specify { expect(user.invalid_ancestry?).to eq(false) }
    specify { expect { user.validate_ancestry }.not_to(change { user.errors.messages }) }

    context do
      let(:author_attributes) { {} }

      specify { expect(user.validate_ancestry).to eq(false) }
      specify { expect { user.validate_ancestry! }.to raise_error Granite::Form::ValidationError }
      specify { expect(user.valid_ancestry?).to eq(false) }
      specify { expect(user.invalid_ancestry?).to eq(true) }

      specify do
        expect { user.validate_ancestry }.to change { user.errors.messages }
          .to('projects.0.author.name': ["can't be blank"])
      end
    end

    context do
      let(:profile) { Profile.new }

      specify { expect(user.validate_ancestry).to eq(false) }
      specify { expect { user.validate_ancestry! }.to raise_error Granite::Form::ValidationError }
      specify { expect(user.valid_ancestry?).to eq(false) }
      specify { expect(user.invalid_ancestry?).to eq(true) }

      specify do
        expect { user.validate_ancestry }.to change { user.errors.messages }
          .to('profile.first_name': ["can't be blank"])
      end
    end

    context do
      let(:projects) { [project, Project.new] }

      specify { expect(user.validate_ancestry).to eq(false) }
      specify { expect { user.validate_ancestry! }.to raise_error Granite::Form::ValidationError }
      specify { expect(user.valid_ancestry?).to eq(false) }
      specify { expect(user.invalid_ancestry?).to eq(true) }

      specify do
        expect { user.validate_ancestry }.to change { user.errors.messages }
          .to('projects.1.title': ["can't be blank"])
      end

      context do
        before { user.update(login: '') }

        specify do
          expect { user.validate_ancestry }.to change { user.errors.messages }
            .to('projects.1.title': ["can't be blank"], login: ["can't be blank"])
        end
      end
    end
  end
end
