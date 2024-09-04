require 'spec_helper'

RSpec.describe Granite::Form::ActiveRecord::Associations do
  before do
    stub_model(:project) do
      include Granite::Form::Model::Persistence
      include Granite::Form::Model::Associations

      attribute :title, String

      validates :title, presence: true

      embeds_one :author do
        attribute :name, String

        validates :name, presence: true
      end
    end

    stub_model(:profile) do
      include Granite::Form::Model::Persistence
      include Granite::Form::Model::Associations

      attribute :first_name, String
      attribute :last_name, String
      attribute :admin, Boolean
    end

    stub_class(:user, ActiveRecord::Base) do
      embeds_many :projects
      embeds_one :profile

      # Simulating JSON attribute
      serialize :projects, JSON

      def read_attribute(name)
        if name.to_s == 'projects'
          value = super
          JSON.parse(value) if value
        else
          super
        end
      end

      validates :projects, associated: true
    end
  end

  let(:user) { User.new }

  specify { expect(user.projects).to eq([]) }
  specify { expect(user.profile).to be_nil }

  context 'new owner' do
    let(:user) { User.new }

    describe '#projects' do
      specify do
        expect { user.projects << Project.new }
          .not_to(change { user.read_attribute(:projects) })
      end

      specify do
        expect { user.projects << Project.new(title: 'First') }
          .not_to(change { user.read_attribute(:projects) })
      end

      specify do
        expect { user.projects << Project.new(title: 'First') }
          .not_to(change { user.projects.reload.count })
      end

      specify do
        user.projects << Project.new(title: 'First')
        user.save
        expect(user.reload.projects.first.title).to eq('First')
      end
    end

    describe '#profile' do
      specify do
        expect { user.profile = Profile.new(first_name: 'google.com') }
          .not_to(change { user.read_attribute(:profile) })
      end

      specify do
        expect { user.profile = Profile.new(first_name: 'google.com') }
          .to change { user.profile }.from(nil).to(an_instance_of(Profile))
      end

      specify do
        user.profile = Profile.new(first_name: 'google.com')
        user.save
        expect(user.reload.profile.first_name).to eq('google.com')
      end

      context 'with profile already set' do
        before do
          user.build_profile(admin: true)
          user.save!
        end

        specify do
          user.profile.admin = false
          user.save
          expect(user.reload.profile.admin).to eq(false)
        end
      end
    end
  end

  context 'persisted owner' do
    let(:user) { User.create }

    describe '#projects' do
      specify do
        expect { user.projects << Project.new(title: 'First') }
          .not_to(change { user.read_attribute(:projects) })
      end

      specify do
        user.projects << Project.new(title: 'First')
        user.save
        expect(user.reload.projects.first.title).to eq('First')
      end

      context do
        let(:project) { Project.new(title: 'First') }

        before { project.build_author(name: 'Author') }

        specify do
          expect { user.projects << project }
            .not_to(change { user.read_attribute(:projects) })
        end

        specify do
          expect do
            user.projects << project
            user.save
          end
            .to change { user.reload.read_attribute(:projects) }.from([])
            .to([{ 'title' => 'First', 'author' => { 'name' => 'Author' } }])
        end
      end
    end

    describe '#profile' do
      specify do
        expect { user.profile = Profile.new(first_name: 'google.com') }
          .to change { user.profile }.from(nil).to(an_instance_of(Profile))
      end

      specify do
        user.profile = Profile.new(first_name: 'google.com')
        user.save
        expect(user.reload.profile.first_name).to eq('google.com')
      end

      specify do
        expect { user.profile = Profile.new(first_name: 'google.com') }
          .not_to(change { user.read_attribute(:profile) })
      end

      specify do
        expect do
          user.profile = Profile.new(first_name: 'google.com')
          user.save
        end
          .to change { user.reload.read_attribute(:profile) }.from(nil)
          .to({ first_name: 'google.com', last_name: nil, admin: nil }.to_json)
      end
    end
  end

  context 'class determine errors' do
    specify do
      expect do
        stub_class(:book, ActiveRecord::Base) do
          embeds_one :author, class_name: 'Borogoves'
        end.reflect_on_association(:author).klass
      end.to raise_error NameError
    end

    specify do
      expect do
        stub_class(:user, ActiveRecord::Base) do
          embeds_many :projects, class_name: 'Borogoves' do
            attribute :title
          end
        end.reflect_on_association(:projects).klass
      end.to raise_error NameError
    end
  end

  context 'on the fly' do
    before do
      stub_class(:user, ActiveRecord::Base) do
        embeds_many :projects do
          attribute :title, String
        end
        embeds_one :profile, class_name: 'Profile' do
          attribute :age, Integer
        end
      end
    end

    specify { expect(User.reflect_on_association(:projects).klass).to eq(User::Project) }
    specify { expect(User.new.projects).to eq([]) }

    specify do
      expect(User.new.tap { |u| u.projects.build(title: 'Project') }.projects)
        .to be_a(Granite::Form::Model::Associations::Collection::Embedded)
    end

    specify do
      expect(User.new.tap { |u| u.projects.build(title: 'Project') }.projects)
        .to match([have_attributes(title: 'Project')])
    end

    specify { expect(User.reflect_on_association(:profile).klass).to eq(User::Profile) }
    specify { expect(User.reflect_on_association(:profile).klass).to be < Profile }
    specify { expect(User.new.profile).to be_nil }
    specify { expect(User.new.tap { |u| u.build_profile(first_name: 'Profile') }.profile).to be_a(User::Profile) }

    specify do
      expect(User.new.tap { |u| u.build_profile(first_name: 'Profile') }.profile)
        .to have_attributes(first_name: 'Profile', last_name: nil, admin: nil, age: nil)
    end
  end
end
