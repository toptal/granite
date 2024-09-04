require 'spec_helper'

RSpec.describe Granite::Form::Model::Associations::EmbedsMany do
  before do
    stub_model(:dummy) do
      include Granite::Form::Model::Associations
    end

    stub_model(:project) do
      include Granite::Form::Model::Persistence
      include Granite::Form::Model::Associations

      attribute :title, String
      validates :title, presence: true
    end
    stub_model(:user) do
      include Granite::Form::Model::Persistence
      include Granite::Form::Model::Associations

      attribute :name, String
      embeds_many :projects
    end
  end

  let(:user) { User.new(name: 'User') }
  let(:association) { user.association(:projects) }

  let(:existing_user) { User.instantiate name: 'Rick', projects: [{ title: 'Genesis' }] }
  let(:existing_association) { existing_user.association(:projects) }

  context 'callbacks' do
    before do
      User.class_eval do
        embeds_many :projects,
                    before_add: ->(object) { callbacks.push([:before_add, object]) },
                    after_add: ->(object) { callbacks.push([:after_add, object]) }

        collection :callbacks, Array
      end
    end

    let(:project1) { Project.new(title: 'Project1') }
    let(:project2) { Project.new(title: 'Project2') }

    specify do
      expect { association.build(title: 'Project1') }
        .to change { user.callbacks }
        .to([[:before_add, project1], [:after_add, project1]])
    end

    specify do
      expect do
        association.build(title: 'Project1')
        association.build(title: 'Project2')
      end
        .to change { user.callbacks }
        .to([
              [:before_add, project1], [:after_add, project1],
              [:before_add, project2], [:after_add, project2]
            ])
    end

    specify do
      expect { association.concat(project1, project2) }
        .to change { user.callbacks }
        .to([
              [:before_add, project1], [:after_add, project1],
              [:before_add, project2], [:after_add, project2]
            ])
    end

    specify do
      expect do
        association.concat(project1)
        association.concat(project2)
      end
        .to change { user.callbacks }
        .to([
              [:before_add, project1], [:after_add, project1],
              [:before_add, project2], [:after_add, project2]
            ])
    end

    specify do
      expect { association.writer([project2, project1]) }
        .to change { user.callbacks }
        .to([
              [:before_add, project2], [:after_add, project2],
              [:before_add, project1], [:after_add, project1]
            ])
    end

    specify do
      expect do
        association.writer([project1])
        association.writer([])
        association.writer([project2])
      end
        .to change { user.callbacks }
        .to([
              [:before_add, project1], [:after_add, project1],
              [:before_add, project2], [:after_add, project2]
            ])
    end

    context 'default' do
      before do
        User.class_eval do
          embeds_many :projects,
                      before_add: ->(owner, object) { owner.callbacks.push([:before_add, object]) },
                      after_add: ->(owner, object) { owner.callbacks.push([:after_add, object]) },
                      default: -> { { title: 'Project1' } }

          collection :callbacks, Array
        end
      end

      specify do
        expect { association.concat(project2) }
          .to change { user.callbacks }
          .to([
                [:before_add, project2], [:after_add, project2],
                [:before_add, project1], [:after_add, project1]
              ])
      end
    end
  end

  describe 'user#association' do
    specify { expect(association).to be_a described_class }
    specify { expect(association).to eq(user.association(:projects)) }
  end

  describe 'project#embedder' do
    let(:project) { Project.new(title: 'Project') }

    specify { expect(association.build.embedder).to eq(user) }

    specify do
      expect { association.writer([project]) }
        .to change { project.embedder }.from(nil).to(user)
    end

    specify do
      expect { association.concat(project) }
        .to change { project.embedder }.from(nil).to(user)
    end

    specify do
      expect { association.target = [project] }
        .to change { project.embedder }.from(nil).to(user)
    end

    context 'default' do
      before do
        User.class_eval do
          embeds_many :projects, default: -> { { title: 'Project1' } }
        end
      end

      specify { expect(association.target.first.embedder).to eq(user) }

      context do
        before do
          User.class_eval do
            embeds_many :projects, default: -> { Project.new(title: 'Project1') }
          end
        end

        specify { expect(association.target.first.embedder).to eq(user) }
      end
    end

    context 'embedding goes before attributes' do
      before do
        Project.class_eval do
          attribute :title, String, normalize: ->(value) { "#{value}#{embedder.name}" }
        end
      end

      specify { expect(association.build(title: 'Project').title).to eq('ProjectUser') }
    end
  end

  describe '#build' do
    specify { expect(association.build).to be_a Project }
    specify { expect(association.build).not_to be_persisted }

    specify do
      expect { association.build(title: 'Swordfish') }
        .not_to(change { user.read_attribute(:projects) })
    end

    specify do
      expect { association.build(title: 'Swordfish') }
        .to change { association.reader.map(&:attributes) }
        .from([]).to([{ 'title' => 'Swordfish' }])
    end

    specify do
      expect { existing_association.build(title: 'Swordfish') }
        .not_to(change { existing_user.read_attribute(:projects) })
    end

    specify do
      expect { existing_association.build(title: 'Swordfish') }
        .to change { existing_association.reader.map(&:attributes) }
        .from([{ 'title' => 'Genesis' }]).to([{ 'title' => 'Genesis' }, { 'title' => 'Swordfish' }])
    end
  end

  describe '#target' do
    specify { expect(association.target).to eq([]) }
    specify { expect(existing_association.target).to eq(existing_user.projects) }
    specify { expect { association.build }.to change { association.target.count }.to(1) }
  end

  describe '#default' do
    before do
      User.embeds_many :projects, default: -> { { title: 'Default' } }
      Project.class_eval do
        include Granite::Form::Model::Primary
        primary :title
      end
    end

    let(:new_project) { Project.new.tap { |p| p.title = 'Project' } }
    let(:existing_user) { User.instantiate name: 'Rick' }

    specify { expect(association.target.map(&:title)).to eq(['Default']) }
    specify { expect(association.target.map(&:new_record?)).to eq([true]) }

    specify do
      expect { association.replace([new_project]) }
        .to change { association.target.map(&:title) }
        .to eq(['Project'])
    end

    specify { expect { association.replace([]) }.to change { association.target }.to([]) }

    specify { expect(existing_association.target).to eq([]) }

    specify do
      expect { existing_association.replace([new_project]) }
        .to change { existing_association.target.map(&:title) }
        .to(['Project'])
    end

    specify { expect { existing_association.replace([]) }.not_to(change { existing_association.target }) }

    context do
      before { Project.include Granite::Form::Model::Dirty }

      specify { expect(association.target.any?(&:changed?)).to eq(false) }
    end
  end

  describe '#loaded?' do
    specify { expect(association.loaded?).to eq(false) }
    specify { expect { association.target }.to change { association.loaded? }.to(true) }
    specify { expect { association.build }.to change { association.loaded? }.to(true) }
    specify { expect { association.replace([]) }.to change { association.loaded? }.to(true) }
    specify { expect { existing_association.replace([]) }.to change { existing_association.loaded? }.to(true) }
  end

  describe '#reload' do
    specify { expect(association.reload).to eq([]) }

    specify { expect(existing_association.reload).to eq(existing_user.projects) }

    context do
      before { association.build(title: 'Swordfish') }

      specify do
        expect { association.reload }
          .to change { association.reader.map(&:attributes) }.from([{ 'title' => 'Swordfish' }]).to([])
      end
    end

    context do
      before { existing_association.build(title: 'Swordfish') }

      specify do
        expect { existing_association.reload }
          .to change { existing_association.reader.map(&:attributes) }
          .from([{ 'title' => 'Genesis' }, { 'title' => 'Swordfish' }]).to([{ 'title' => 'Genesis' }])
      end
    end
  end

  describe '#sync' do
    let!(:project) { association.build(title: 'Genesis') }

    specify do
      expect { association.sync }.to change { user.read_attribute(:projects) }.from(nil).to([{ 'title' => 'Genesis' }])
    end

    context 'when embedding is nested' do
      before do
        Project.class_eval do
          include Granite::Form::Model::Associations

          embeds_one :deadline do
            attribute :enabled, Boolean
          end
        end

        project.build_deadline(enabled: true)
      end

      specify do
        expect { association.sync }.to change { user.read_attribute(:projects) }
          .from(nil).to([{ 'title' => 'Genesis', 'deadline' => { 'enabled' => true } }])
      end
    end
  end

  describe '#clear' do
    specify { expect(association.clear).to eq(true) }
    specify { expect { association.clear }.not_to(change { association.reader }) }

    specify { expect(existing_association.clear).to eq(true) }

    specify do
      expect { existing_association.clear }
        .to change { existing_association.reader.map(&:attributes) }.from([{ 'title' => 'Genesis' }]).to([])
    end
  end

  describe '#reader' do
    specify { expect(association.reader).to eq([]) }

    specify { expect(existing_association.reader.first).to be_a Project }
    specify { expect(existing_association.reader.first).to be_persisted }

    context do
      before { association.build }

      specify { expect(association.reader.last).to be_a Project }
      specify { expect(association.reader.last).not_to be_persisted }
      specify { expect(association.reader.size).to eq(1) }
      specify { expect(association.reader(true)).to eq([]) }
    end

    context do
      before { existing_association.build(title: 'Swordfish') }

      specify { expect(existing_association.reader.size).to eq(2) }
      specify { expect(existing_association.reader.last.title).to eq('Swordfish') }
      specify { expect(existing_association.reader(true).size).to eq(1) }
      specify { expect(existing_association.reader(true).last.title).to eq('Genesis') }
    end
  end

  describe '#writer' do
    let(:new_project1) { Project.new(title: 'Project 1') }
    let(:new_project2) { Project.new(title: 'Project 2') }
    let(:invalid_project) { Project.new }

    specify do
      expect { association.writer([Dummy.new]) }
        .to raise_error Granite::Form::AssociationTypeMismatch
    end

    specify { expect { association.writer(nil) }.to raise_error NoMethodError }
    specify { expect { association.writer(new_project1) }.to raise_error NoMethodError }
    specify { expect(association.writer([])).to eq([]) }

    specify { expect(association.writer([new_project1])).to eq([new_project1]) }

    specify do
      expect { association.writer([new_project1]) }
        .to change { association.reader.map(&:attributes) }.from([]).to([{ 'title' => 'Project 1' }])
    end

    specify do
      expect { existing_association.writer([new_project1, Dummy.new, new_project2]) }
        .to raise_error Granite::Form::AssociationTypeMismatch
    end

    specify do
      expect do
        muffle(Granite::Form::AssociationTypeMismatch) do
          existing_association.writer([new_project1, Dummy.new, new_project2])
        end
      end.not_to(change { existing_association.reader })
    end

    specify { expect { existing_association.writer(nil) }.to raise_error NoMethodError }

    specify do
      expect { muffle(NoMethodError) { existing_association.writer(nil) } }
        .not_to(change { existing_association.reader })
    end

    specify { expect(existing_association.writer([])).to eq([]) }

    specify do
      expect { existing_association.writer([]) }
        .to change { existing_association.reader }.to([])
    end

    specify { expect(existing_association.writer([new_project1, new_project2])).to eq([new_project1, new_project2]) }

    specify do
      expect { existing_association.writer([new_project1, new_project2]) }
        .to change { existing_association.reader.map(&:attributes) }
        .from([{ 'title' => 'Genesis' }]).to([{ 'title' => 'Project 1' }, { 'title' => 'Project 2' }])
    end
  end

  describe '#concat' do
    let(:new_project1) { Project.new(title: 'Project 1') }
    let(:new_project2) { Project.new(title: 'Project 2') }
    let(:invalid_project) { Project.new }

    specify do
      expect { association.concat(Dummy.new) }
        .to raise_error Granite::Form::AssociationTypeMismatch
    end

    specify { expect { association.concat(nil) }.to raise_error Granite::Form::AssociationTypeMismatch }
    specify { expect(association.concat([])).to eq([]) }
    specify { expect(existing_association.concat([])).to eq(existing_user.projects) }
    specify { expect(existing_association.concat).to eq(existing_user.projects) }

    specify { expect(association.concat(new_project1)).to eq([new_project1]) }

    specify do
      expect { association.concat(new_project1) }
        .to change { association.reader.map(&:attributes) }.from([]).to([{ 'title' => 'Project 1' }])
    end

    specify do
      expect { association.concat(new_project1) }
        .not_to(change { user.read_attribute(:projects) })
    end

    specify do
      expect { existing_association.concat(new_project1, invalid_project) }
        .to change { existing_association.reader.map(&:attributes) }
        .from([{ 'title' => 'Genesis' }])
        .to([
              { 'title' => 'Genesis' },
              { 'title' => 'Project 1' },
              { 'title' => nil }
            ])
    end

    specify do
      expect { existing_association.concat(new_project1, Dummy.new, new_project2) }
        .to raise_error Granite::Form::AssociationTypeMismatch
    end

    specify do
      expect do
        muffle(Granite::Form::AssociationTypeMismatch) do
          existing_association.concat(new_project1, Dummy.new, new_project2)
        end
      end
        .to change { existing_association.reader.map(&:attributes) }
        .from([{ 'title' => 'Genesis' }]).to([{ 'title' => 'Genesis' }, { 'title' => 'Project 1' }])
    end

    specify do
      expect(existing_association.concat(new_project1, new_project2))
        .to eq([existing_user.projects.first, new_project1, new_project2])
    end

    specify do
      expect { existing_association.concat([new_project1, new_project2]) }
        .to change { existing_association.reader.map(&:attributes) }
        .from([{ 'title' => 'Genesis' }]).to([{ 'title' => 'Genesis' },
                                              { 'title' => 'Project 1' },
                                              { 'title' => 'Project 2' }])
    end
  end
end
