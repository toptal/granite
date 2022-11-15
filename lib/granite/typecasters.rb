require 'granite/form'

Granite::Form.typecaster('Granite::Action::Types::Collection') do |value, attribute|
  typecaster = Granite::Form.typecaster(attribute.type.subtype)
  if value.respond_to? :transform_values
    value.transform_values { |v| typecaster.call(v, attribute) }
  elsif value.respond_to?(:map)
    value.map { |v| typecaster.call(v, attribute) }
  end
end
