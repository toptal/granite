module RuboCop
  module Granite
    PROJECT_ROOT   = Pathname.new(__dir__).parent.parent.expand_path.freeze
    CONFIG_DEFAULT = PROJECT_ROOT.join('config', 'rubocop-default.yml').freeze
    CONFIG         = YAML.safe_load(CONFIG_DEFAULT.read).freeze

    private_constant(:CONFIG_DEFAULT, :PROJECT_ROOT)
  end
end
