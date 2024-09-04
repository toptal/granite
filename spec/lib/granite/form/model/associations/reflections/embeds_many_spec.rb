require 'spec_helper'

RSpec.describe Granite::Form::Model::Associations::Reflections::EmbedsMany do
  before do
    stub_model_granite_form(:project) do
      include Granite::Form::Model::Persistence
      include Granite::Form::Model::Associations
      attribute :title, String
    end
    stub_model_granite_form(:user) do
      include Granite::Form::Model::Associations

      attribute :name, String
      embeds_many :projects
    end
  end

  let(:user) { User.new }

  context ':read, :write' do
    before do
      stub_model_granite_form(:user) do
        include Granite::Form::Model::Persistence
        include Granite::Form::Model::Associations

        attribute :name
        embeds_many :projects,
                    read: lambda { |reflection, object|
                      value = object.instance_variable_get("@_value_#{reflection.name}")
                      JSON.parse(value) if value.present?
                    },
                    write: lambda { |reflection, object, value|
                      value = value.to_json if value
                      object.instance_variable_set("@_value_#{reflection.name}", value)
                    }
      end
    end

    let(:user) { User.new }
    let(:new_project1) { Project.new(title: 'Project 1') }
    let(:new_project2) { Project.new(title: 'Project 2') }

    specify do
      expect do
        user.projects = [new_project1, new_project2]
        user.association(:projects).sync
      end
        .to change { user.projects(true).reload }
        .from([])
        .to([have_attributes(title: 'Project 1'), have_attributes(title: 'Project 2')])
    end
  end

  describe '#projects' do
    specify { expect(user.projects).to eq([]) }

    describe '#build' do
      let(:project) { Project.new title: 'Project' }

      specify { expect(user.projects.build(title: 'Project')).to eq(project) }
      # specify { expect { user.projects.build(title: 'Project') }.to change { user.projects }.from([]).to([project]) }
    end

    describe '#reload' do
      let(:project) { Project.new title: 'Project' }

      before do
        user.write_attribute(:projects, [{ title: 'Project' }])
        user.projects.build
      end

      specify { expect(user.projects.count).to eq(2) }
      specify { expect(user.projects.reload).to eq([project]) }
    end

    describe '#concat' do
      let(:project) { Project.new title: 'Project' }

      # specify { expect { user.projects.concat project }.to change { user.projects }.from([]).to([project]) }

      specify do
        expect do
          user.projects.concat project, 'string'
        end.to raise_error Granite::Form::AssociationTypeMismatch
      end

      context do
        let(:other) { Project.new title: 'Other' }

        before { user.projects = [other] }

        # specify do
        #   expect { user.projects.concat project }
        #     .to change { user.projects }
        #     .from([other])
        #     .to([other, project])
        # end
      end
    end
  end

  describe '#projects=' do
    let(:project) { Project.new title: 'Project' }

    specify { expect { user.projects = [] }.not_to change { user.projects }.from([]) }
    # specify { expect { user.projects = [project] }.to change { user.projects }.from([]).to([project]) }
    specify { expect { user.projects = [project, 'string'] }.to raise_error Granite::Form::AssociationTypeMismatch }

    context do
      let(:other) { Project.new title: 'Other' }

      before { user.projects = [other] }

      # specify { expect { user.projects = [project] }.to change { user.projects }.from([other]).to([project]) }
      # specify { expect { user.projects = [] }.to change { user.projects }.from([other]).to([]) }
    end
  end

  context 'on the fly' do
    context do
      before do
        stub_model_granite_form(:user) do
          include Granite::Form::Model::Associations

          attribute :title, String
          embeds_many :projects do
            attribute :title, String
          end
        end
      end

      specify { expect(User.reflect_on_association(:projects).klass).to eq(User::Project) }
      specify { expect(User.new.projects).to eq([]) }

      specify do
        user = User.new
        user.projects.build(title: 'Project')
        expect(user.projects).to be_a(Granite::Form::Model::Associations::Collection::Embedded)
      end

      specify do
        user = User.new
        user.projects.build(title: 'Project')
        expect(user.projects).to match([have_attributes(title: 'Project')])
      end
    end

    context do
      before do
        stub_model_granite_form(:user) do
          include Granite::Form::Model::Associations

          attribute :title, String
          embeds_many :projects, class_name: 'Project' do
            attribute :value, String
          end
        end
      end

      specify { expect(User.reflect_on_association(:projects).klass).to eq(User::Project) }
      specify { expect(User.new.projects).to eq([]) }

      specify do
        user = User.new
        user.projects.build(title: 'Project')
        expect(user.projects)
          .to be_a(Granite::Form::Model::Associations::Collection::Embedded)
          .and match([have_attributes(title: 'Project', value: nil)])
      end
    end
  end
end
