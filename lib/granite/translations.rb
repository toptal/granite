module Granite
  class Translations
    class << self
      def combine_paths(paths1, paths2)
        paths1.flat_map do |path1|
          paths2.map { |path2| [*path1, *path2].join('.') }
        end
      end

      def scope_translation_args(scopes, key, *, **options)
        lookups = expand_relative_key(scopes, key) + Array(options[:default])

        key = lookups.shift
        options[:default] = lookups

        [key, options]
      end

      private

      def expand_relative_key(scopes, key)
        return [key] unless key.is_a?(String) && key.start_with?('.')

        combine_paths(scopes, [key.sub(/^\./, '')]).map(&:to_sym)
      end
    end
  end
end
