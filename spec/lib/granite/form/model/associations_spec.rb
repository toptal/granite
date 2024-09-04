require 'spec_helper'

RSpec.describe Granite::Form::Model::Associations do
  context do
    before do
      stub_model_granite_form(:nobody) do
        include Granite::Form::Model::Associations
      end
      stub_model_granite_form(:project) do
        include Granite::Form::Model::Persistence
      end
      stub_model_granite_form(:user, Nobody) do
        include Granite::Form::Model::Associations
        embeds_many :projects
      end
      stub_model_granite_form(:manager, Nobody) do
        include Granite::Form::Model::Associations
        embeds_one :managed_project, class_name: 'Project'
      end
      stub_model_granite_form(:admin, User) do
        include Granite::Form::Model::Associations
        embeds_many :admin_projects, class_name: 'Project'

        alias_association :own_projects, :admin_projects
      end
    end

    describe '#reflections' do
      specify { expect(Nobody.reflections.keys).to eq([]) }
      specify { expect(User.reflections.keys).to eq([:projects]) }
      specify { expect(Manager.reflections.keys).to eq([:managed_project]) }
      specify { expect(Admin.reflections.keys).to eq(%i[projects admin_projects]) }
    end

    describe '#reflect_on_association' do
      specify { expect(Nobody.reflect_on_association(:blabla)).to be_nil }

      specify do
        expect(Admin.reflect_on_association('projects'))
          .to be_a Granite::Form::Model::Associations::Reflections::EmbedsMany
      end

      specify { expect(Admin.reflect_on_association('own_projects').name).to eq(:admin_projects) }

      specify do
        expect(Manager.reflect_on_association(:managed_project))
          .to be_a Granite::Form::Model::Associations::Reflections::EmbedsOne
      end
    end
  end

  context 'class determine errors' do
    specify do
      expect do
        stub_model_granite_form do
          include Granite::Form::Model::Associations

          embeds_one :author, class_name: 'Borogoves'
        end.reflect_on_association(:author).data_source
      end.to raise_error NameError
    end

    specify do
      expect do
        stub_model_granite_form(:user) do
          include Granite::Form::Model::Associations

          embeds_many :projects, class_name: 'Borogoves' do
            attribute :title
          end
        end.reflect_on_association(:projects).data_source
      end.to raise_error NameError
    end
  end

  context do
    before do
      stub_model_granite_form(:project) do
        include Granite::Form::Model::Persistence
        include Granite::Form::Model::Associations

        attribute :title, String

        validates :title, presence: true

        embeds_one :author do
          attribute :name, String

          validates :name, presence: true
        end
      end

      stub_model_granite_form(:profile) do
        include Granite::Form::Model::Persistence

        attribute :first_name, String
        attribute :last_name, String

        validates :first_name, presence: true
      end

      stub_model_granite_form(:user) do
        include Granite::Form::Model::Associations

        attribute :login, Object

        validates :login, presence: true

        embeds_one :profile
        embeds_many :projects

        alias_association :my_profile, :profile
      end
    end

    let(:user) { User.new }

    specify { expect(user.projects).to eq([]) }
    specify { expect(user.profile).to be_nil }

    describe '.inspect' do
      specify do
        expect(User.inspect).to eq('User(profile: EmbedsOne(Profile), projects: EmbedsMany(Project), login: Object)')
      end
    end

    describe '.association_names' do
      specify { expect(User.association_names).to eq(%i[profile projects]) }
    end

    describe '#inspect' do
      let(:profile) { Profile.new first_name: 'Name' }
      let(:project) { Project.new title: 'Project' }

      specify do
        expect(User.new(login: 'Login', profile: profile, projects: [project]).inspect)
          .to eq('#<User profile: #<EmbedsOne #<Profile first_name: "Name", last_name: nil>>, projects: #<EmbedsMany [#<Project author: #<EmbedsOne nil>, title: "P...]>, login: "Login">') # rubocop:disable Layout/LineLength
      end
    end

    describe '#==' do
      let(:project) { Project.new title: 'Project' }
      let(:other) { Project.new title: 'Other' }

      specify { expect(User.new(projects: [project])).to eq(User.new(projects: [project])) }
      specify { expect(User.new(projects: [project])).not_to eq(User.new(projects: [other])) }
      specify { expect(User.new(projects: [project])).not_to eq(User.new) }

      specify { expect(User.new(projects: [project])).to eql(User.new(projects: [project])) }
      specify { expect(User.new(projects: [project])).not_to eql(User.new(projects: [other])) }
      specify { expect(User.new(projects: [project])).not_to eql(User.new) }

      context do
        before { User.include Granite::Form::Model::Primary }

        let(:user) { User.new(projects: [project]) }

        specify { expect(user).to eq(user.clone.tap { |b| b.projects(author: project) }) }
        specify { expect(user).to eq(user.clone.tap { |b| b.projects(author: other) }) }

        specify { expect(user).to eql(user.clone.tap { |b| b.projects(author: project) }) }
        specify { expect(user).to eql(user.clone.tap { |b| b.projects(author: other) }) }
      end
    end

    describe '#association' do
      specify { expect(user.association(:projects)).to be_a(Granite::Form::Model::Associations::EmbedsMany) }
      specify { expect(user.association(:profile)).to be_a(Granite::Form::Model::Associations::EmbedsOne) }
      specify { expect(user.association(:blabla)).to be_nil }
      specify { expect(user.association('my_profile').reflection.name).to eq(:profile) }
      specify { expect(user.association('my_profile')).to equal(user.association(:profile)) }
    end

    describe '#association_names' do
      specify { expect(user.association_names).to eq(%i[profile projects]) }
    end

    describe '#instantiate' do
      before do
        User.include Granite::Form::Model::Persistence
        project.build_author(name: 'Author')
      end

      let(:profile) { Profile.new first_name: 'Name' }
      let(:project) { Project.new title: 'Project' }
      let(:user) { User.new(profile: profile, projects: [project]) }

      specify { expect(User.instantiate(JSON.parse(user.to_json))).to eq(user) }

      specify do
        expect(User.instantiate(JSON.parse(user.to_json))
        .tap { |u| u.projects.first.author.name = 'Other' }).not_to eq(user)
      end
    end
  end
end
