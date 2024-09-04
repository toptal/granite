shared_context 'type setup' do |type_name|
  let(:model) { stub_model { attribute :column, type_name.constantize } }

  def typecast(value)
    model.new(column: value).column
  end
end
