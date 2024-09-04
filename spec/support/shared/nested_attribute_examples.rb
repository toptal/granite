require 'spec_helper'

shared_examples 'nested attributes' do
  before do
    stub_model :project do
      include Granite::Form::Model::Primary
      include Granite::Form::Model::Associations

      primary :slug, String
      attribute :title, String
    end

    stub_model :profile do
      include Granite::Form::Model::Primary
      include Granite::Form::Model::Associations

      primary :identifier
      attribute :first_name, String
    end
  end

  context 'embeds_one' do
    let(:user) { User.new }

    specify { expect { user.profile_attributes = {} }.to change { user.profile }.to(an_instance_of(Profile)) }

    specify do
      expect { user.profile_attributes = { first_name: 'User' } }
        .to change { user.profile.try(:first_name) }
        .to('User')
    end

    specify do
      expect do
        user.profile_attributes = { identifier: 42, first_name: 'User' }
      end.to raise_error Granite::Form::ObjectNotFound
    end

    context ':reject_if' do
      context do
        before { User.accepts_nested_attributes_for :profile, reject_if: :all_blank }

        specify { expect { user.profile_attributes = { first_name: '' } }.not_to(change { user.profile }) }
      end

      context do
        before do
          User.accepts_nested_attributes_for :profile, reject_if: lambda { |attributes|
                                                                    attributes['first_name'].blank?
                                                                  }
        end

        specify { expect { user.profile_attributes = { first_name: '' } }.not_to(change { user.profile }) }
      end
    end

    context 'existing' do
      let(:profile) { Profile.new(first_name: 'User') }
      let(:user) { User.new profile: profile }

      specify do
        expect do
          user.profile_attributes = { identifier: 42, first_name: 'User' }
        end.to raise_error Granite::Form::ObjectNotFound
      end

      specify do
        expect { user.profile_attributes = { identifier: profile.identifier.to_s, first_name: 'User 1' } }
          .to change { user.profile.first_name }.to('User 1')
      end

      specify do
        expect { user.profile_attributes = { first_name: 'User 1' } }
          .to change { user.profile.first_name }.to('User 1')
      end

      specify do
        expect { user.profile_attributes = { first_name: 'User 1', _destroy: '1' } }
          .not_to(change { user.profile.first_name })
      end

      specify do
        expect do
          user.profile_attributes = { first_name: 'User 1', _destroy: '1' }
        end.not_to(change { user.profile.first_name })
      end

      specify do
        expect do
          user.profile_attributes = { identifier: profile.identifier.to_s, first_name: 'User 1', _destroy: '1' }
        end.to change { user.profile.first_name }.to('User 1')
      end

      context ':allow_destroy' do
        before { User.accepts_nested_attributes_for :profile, allow_destroy: true }

        specify do
          expect { user.profile_attributes = { first_name: 'User 1', _destroy: '1' } }
            .not_to(change { user.profile.first_name })
        end

        specify do
          expect do
            user.profile_attributes = { identifier: profile.identifier.to_s, first_name: 'User 1', _destroy: '1' }
          end.to change { user.profile }.to(nil)
        end
      end

      context ':update_only' do
        before { User.accepts_nested_attributes_for :profile, update_only: true }

        specify do
          expect { user.profile_attributes = { identifier: 42, first_name: 'User 1' } }
            .to change { user.profile.first_name }.to('User 1')
        end
      end
    end

    context 'not primary' do
      before do
        stub_model :profile do
          attribute :identifier, Integer
          attribute :first_name, String
        end
      end

      specify { expect { user.profile_attributes = {} }.to change { user.profile }.to(an_instance_of(Profile)) }

      specify do
        expect { user.profile_attributes = { first_name: 'User' } }
          .to change { user.profile.try(:first_name) }.to('User')
      end

      context do
        let(:profile) { Profile.new(first_name: 'User') }
        let(:user) { User.new profile: profile }

        specify do
          expect { user.profile_attributes = { identifier: 42, first_name: 'User 1' } }
            .to change { user.profile.first_name }.to('User 1')
        end
      end
    end

    context 'generated method overwrites' do
      before do
        User.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def profile_attributes=(args)
            args.reverse_merge!(first_name: 'Default Profile Name')
            super
          end
        RUBY
      end

      it 'allows generated method overwritting' do
        expect { user.profile_attributes = {} }
          .to change { user.profile.try(:first_name) }.to('Default Profile Name')
      end
    end
  end

  context 'embeds_many' do
    let(:user) { User.new }

    specify { expect { user.projects_attributes = {} }.not_to(change { user.projects }) }

    specify do
      expect { user.projects_attributes = [{ title: 'Project 1' }, { title: 'Project 2' }] }
        .to change { user.projects.map(&:title) }.to(['Project 1', 'Project 2'])
    end

    specify do
      expect { user.projects_attributes = { 1 => { title: 'Project 1' }, 2 => { title: 'Project 2' } } }
        .to change { user.projects.map(&:title) }.to(['Project 1', 'Project 2'])
    end

    specify do
      expect { user.projects_attributes = [{ slug: 42, title: 'Project 1' }, { title: 'Project 2' }] }
        .to change { user.projects.map(&:title) }.to(['Project 1', 'Project 2'])
    end

    specify do
      expect { user.projects_attributes = [{ title: '' }, { title: 'Project 2' }] }
        .to change { user.projects.map(&:title) }.to(['', 'Project 2'])
    end

    context ':limit' do
      before { User.accepts_nested_attributes_for :projects, limit: 1 }

      specify do
        expect { user.projects_attributes = [{ title: 'Project 1' }] }
          .to change { user.projects.map(&:title) }.to(['Project 1'])
      end

      specify do
        expect { user.projects_attributes = [{ title: 'Project 1' }, { title: 'Project 2' }] }
          .to raise_error Granite::Form::TooManyObjects
      end
    end

    context ':reject_if' do
      context do
        before { User.accepts_nested_attributes_for :projects, reject_if: :all_blank }

        specify do
          expect { user.projects_attributes = [{ title: '' }, { title: 'Project 2' }] }
            .to change { user.projects.map(&:title) }.to(['Project 2'])
        end
      end

      context do
        before do
          User.accepts_nested_attributes_for :projects, reject_if: lambda { |attributes|
                                                                     attributes['title'].blank?
                                                                   }
        end

        specify do
          expect { user.projects_attributes = [{ title: '' }, { title: 'Project 2' }] }
            .to change { user.projects.map(&:title) }.to(['Project 2'])
        end
      end

      context do
        before do
          User.accepts_nested_attributes_for :projects, reject_if: lambda { |attributes|
                                                                     attributes['foobar'].blank?
                                                                   }
        end

        specify do
          expect { user.projects_attributes = [{ title: '' }, { title: 'Project 2' }] }
            .not_to(change { user.projects })
        end
      end
    end

    context 'existing' do
      let(:projects) { Array.new(2) { |i| Project.new(title: "Project #{i.next}").tap { |pr| pr.slug = 42 + i } } }
      let(:user) { User.new projects: projects }

      specify do
        expect do
          user.projects_attributes = [
            { slug: projects.first.slug.to_i, title: 'Project 3' },
            { title: 'Project 4' }
          ]
        end
          .to change { user.projects.map(&:title) }.to(['Project 3', 'Project 2', 'Project 4'])
      end

      specify do
        expect do
          user.projects_attributes = [
            { slug: projects.first.slug.to_i, title: 'Project 3' },
            { slug: 33, title: 'Project 4' }
          ]
        end
          .to change { user.projects.map(&:slug) }.to(%w[42 43 33])
      end

      specify do
        expect do
          user.projects_attributes = [
            { slug: projects.first.slug.to_i, title: 'Project 3' },
            { slug: 33, title: 'Project 4', _destroy: 1 }
          ]
        end
          .not_to(change { user.projects.map(&:slug) })
      end

      specify do
        expect do
          user.projects_attributes = {
            1 => { slug: projects.first.slug.to_i, title: 'Project 3' },
            2 => { title: 'Project 4' }
          }
        end
          .to change { user.projects.map(&:title) }.to(['Project 3', 'Project 2', 'Project 4'])
      end

      specify do
        expect do
          user.projects_attributes = [
            { slug: projects.first.slug.to_i, title: 'Project 3', _destroy: '1' },
            { title: 'Project 4', _destroy: '1' }
          ]
        end
          .to change { user.projects.map(&:title) }.to(['Project 3', 'Project 2'])
      end

      specify do
        expect do
          user.projects_attributes = [
            { slug: projects.first.slug.to_i, title: 'Project 3', _destroy: '1' },
            { title: 'Project 4', _destroy: '1' }
          ]
        end
          .to change { user.projects.map(&:title) }.to(['Project 3', 'Project 2'])
      end

      context ':allow_destroy' do
        before { User.accepts_nested_attributes_for :projects, allow_destroy: true }

        specify do
          expect do
            user.projects_attributes = [
              { slug: projects.first.slug.to_i, title: 'Project 3', _destroy: '1' },
              { title: 'Project 4', _destroy: '1' }
            ]
          end
            .to change { user.projects.map(&:title) }.to(['Project 2'])
        end
      end

      context ':update_only' do
        before { User.accepts_nested_attributes_for :projects, update_only: true }

        specify do
          expect do
            user.projects_attributes = [
              { slug: projects.first.slug.to_i, title: 'Project 3' },
              { title: 'Project 4' }
            ]
          end
            .to change { user.projects.map(&:title) }.to(['Project 3', 'Project 2'])
        end

        specify do
          expect do
            user.projects_attributes = [
              { slug: projects.last.slug.to_i, title: 'Project 3' },
              { slug: projects.first.slug.to_i.pred, title: 'Project 0' }
            ]
          end
            .to change { user.projects.map(&:title) }.to(['Project 1', 'Project 3'])
        end
      end
    end

    context 'primary absence causes exception' do
      before do
        stub_model :project do
          include Granite::Form::Model::Primary

          attribute :slug, String
          attribute :title, String
        end
      end

      specify { expect { user.projects_attributes = {} }.to raise_error Granite::Form::UndefinedPrimaryAttribute }
    end

    context 'generated method overwrites' do
      before do
        User.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def projects_attributes=(args)
            args << {title: 'Default Project'}
            super
          end
        RUBY
      end

      it 'allows generated method overwritting' do
        expect { user.projects_attributes = [] }
          .to change { user.projects.map(&:title) }.to(['Default Project'])
      end
    end
  end
end
