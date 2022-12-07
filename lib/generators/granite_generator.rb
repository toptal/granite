class GraniteGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  argument :projector, type: :string, required: false
  class_option :collection, type: :boolean, aliases: '-C', desc: 'Generate collection action'

  def create_action
    template 'granite_action.rb.erb', "apq/actions/#{file_path}.rb"
    template 'granite_business_action.rb.erb', "apq/actions/#{class_path.join('/')}/business_action.rb" unless options.collection?
    template 'granite_base_action.rb.erb', 'apq/actions/base_action.rb', skip: true
    template 'granite_action_spec.rb.erb', "spec/apq/actions/#{file_path}_spec.rb"
    empty_directory "apq/actions/#{file_path}/#{projector}" if projector
  end

  private

  def base_class_name
    if options.collection?
      'BaseAction'
    else
      "#{class_path.join('/').camelize}::BusinessAction"
    end
  end

  def subject_name
    class_path.last
  end

  def subject_class_name
    subject_name.classify
  end
end
