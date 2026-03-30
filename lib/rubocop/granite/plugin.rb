require 'lint_roller'
require 'granite/version'

module RuboCop
  module Granite
    # Plugin integration for RuboCop's plugin system (1.72+).
    class Plugin < LintRoller::Plugin
      def about
        LintRoller::About.new(
          name: 'rubocop-granite',
          version: ::Granite::VERSION,
          homepage: 'https://github.com/toptal/granite',
          description: 'Custom RuboCop configuration for Granite'
        )
      end

      def supported?(context)
        context.engine == :rubocop
      end

      def rules(_context)
        project_root = Pathname.new(__dir__).parent.parent.parent.expand_path

        LintRoller::Rules.new(
          type: :path,
          config_format: :rubocop,
          value: project_root.join('config', 'rubocop-default.yml').to_s
        )
      end
    end
  end
end
