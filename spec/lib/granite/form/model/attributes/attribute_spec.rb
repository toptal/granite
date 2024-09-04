require 'spec_helper'

RSpec.describe Granite::Form::Model::Attributes::Attribute do
  before { stub_model(:dummy) }

  def attribute(*args)
    options = args.extract_options!
    Dummy.add_attribute(Granite::Form::Model::Attributes::Reflections::Attribute, :field,
                        { type: Object }.merge(options))
    Dummy.new.attribute(:field)
  end

  describe '#read' do
    let(:field) do
      normalizer = ->(v) { v ? v.strip : v }
      attribute(type: String, normalizer: normalizer, default: :world, enum: %w[hello 42 world])
    end

    specify { expect(field.tap { |r| r.write(nil) }.read).to eq('world') }
    specify { expect(field.tap { |r| r.write(:world) }.read).to eq('world') }
    specify { expect(field.tap { |r| r.write('hello') }.read).to eq('hello') }
    specify { expect(field.tap { |r| r.write(' hello ') }.read).to eq(nil) }
    specify { expect(field.tap { |r| r.write(42) }.read).to eq('42') }
    specify { expect(field.tap { |r| r.write(43) }.read).to eq(nil) }
    specify { expect(field.tap { |r| r.write('') }.read).to eq(nil) }

    context ':readonly' do
      specify { expect(attribute(readonly: true, default: :world).tap { |r| r.write('string') }.read).to eq(:world) }
    end
  end

  describe '#read_before_type_cast' do
    let(:field) { attribute(type: String, normalizer: ->(v) { v.strip }, default: :world, enum: %w[hello 42 world]) }

    specify { expect(field.tap { |r| r.write(nil) }.read_before_type_cast).to eq(:world) }
    specify { expect(field.tap { |r| r.write(:world) }.read_before_type_cast).to eq(:world) }
    specify { expect(field.tap { |r| r.write('hello') }.read_before_type_cast).to eq('hello') }
    specify { expect(field.tap { |r| r.write(42) }.read_before_type_cast).to eq(42) }
    specify { expect(field.tap { |r| r.write(43) }.read_before_type_cast).to eq(43) }
    specify { expect(field.tap { |r| r.write('') }.read_before_type_cast).to eq('') }

    context ':readonly' do
      specify do
        attr = attribute(readonly: true, default: :world)
        attr.write('string')
        expect(attr.read_before_type_cast).to eq(:world)
      end
    end
  end

  describe '#default' do
    before { allow_any_instance_of(Dummy).to receive_messages(value: 42) }

    specify { expect(attribute.default).to eq(nil) }
    specify { expect(attribute(default: 'hello').default).to eq('hello') }
    specify { expect(attribute(default: -> { value }).default).to eq(42) }
  end

  describe '#defaultize' do
    specify { expect(attribute.defaultize(nil)).to be_nil }
    specify { expect(attribute(default: 'hello').defaultize(nil)).to eq('hello') }
    specify { expect(attribute(default: 'hello').defaultize('world')).to eq('world') }
    specify { expect(attribute(default: false, type: Boolean).defaultize(nil)).to eq(false) }
  end

  describe '#normalize' do
    specify { expect(attribute.normalize(' hello ')).to eq(' hello ') }
    specify { expect(attribute(normalizer: ->(v) { v.strip }).normalize(' hello ')).to eq('hello') }

    specify do
      normalizers = [->(v) { v.strip }, ->(v) { v.first(4) }]
      attr = attribute(normalizer: normalizers)
      expect(attr.normalize(' hello ')).to eq('hell')
    end

    specify do
      normalizers = [->(v) { v.first(4) }, ->(v) { v.strip }]
      attr = attribute(normalizer: normalizers)
      expect(attr.normalize(' hello ')).to eq('hel')
    end

    context do
      before { allow_any_instance_of(Dummy).to receive_messages(value: 'value') }

      let(:other) { 'other' }

      specify { expect(attribute(normalizer: ->(_v) { value }).normalize(' hello ')).to eq('value') }
    end

    context 'integration' do
      before do
        config = Granite::Form::Config.send(:new)
        config.types.merge! Granite::Form.config.types
        allow(Granite::Form).to receive_messages(config: config)

        Granite::Form.normalizer(:strip) { |value, _, _| value.strip }
        Granite::Form.normalizer(:trim) do |value, options, _attribute|
          value.first(length || options[:length] || 2)
        end
        Granite::Form.normalizer(:reset) do |value, _options, attribute|
          empty = value.respond_to?(:empty?) ? value.empty? : value.nil?
          empty ? attribute.default : value
        end
      end

      let(:length) { nil }

      specify { expect(attribute(normalizer: :strip).normalize(' hello ')).to eq('hello') }
      specify { expect(attribute(normalizer: %i[strip trim]).normalize(' hello ')).to eq('he') }
      specify { expect(attribute(normalizer: %i[trim strip]).normalize(' hello ')).to eq('h') }
      specify { expect(attribute(normalizer: [:strip, { trim: { length: 4 } }]).normalize(' hello ')).to eq('hell') }
      specify { expect(attribute(normalizer: { strip: {}, trim: { length: 4 } }).normalize(' hello ')).to eq('hell') }

      specify do
        expect(attribute(normalizer: [:strip, { trim: { length: 4 } }, ->(v) { v.last(2) }])
        .normalize(' hello ')).to eq('ll')
      end

      specify { expect(attribute(normalizer: :reset).normalize('')).to eq(nil) }
      specify { expect(attribute(normalizer: %i[strip reset]).normalize('   ')).to eq(nil) }
      specify { expect(attribute(normalizer: :reset, default: '!!!').normalize(nil)).to eq('!!!') }
      specify { expect(attribute(normalizer: :reset, default: '!!!').normalize('')).to eq('!!!') }

      context do
        let(:length) { 3 }

        specify { expect(attribute(normalizer: [:strip, { trim: { length: 4 } }]).normalize(' hello ')).to eq('hel') }
        specify { expect(attribute(normalizer: { strip: {}, trim: { length: 4 } }).normalize(' hello ')).to eq('hel') }

        specify do
          expect(attribute(normalizer: [:strip, { trim: { length: 4 } }, ->(v) { v.last(2) }])
          .normalize(' hello ')).to eq('el')
        end
      end
    end
  end
end
