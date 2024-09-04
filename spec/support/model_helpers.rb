module ModelHelpers
  def stub_model_granite_form(name = nil, superclass = nil, &block)
    stub_class_granite_form(name, superclass) do
      include Granite::Form::Model
    end.tap do |klass|
      klass.class_eval(&block) if block
    end
  end

  def stub_class_granite_form(name = nil, superclass = nil, &block)
    klass = superclass ? Class.new(superclass, &block) : Class.new(&block)
    name.present? ? stub_const(name.to_s.camelize, klass) : klass
  end
end

RSpec.configuration.include ModelHelpers
