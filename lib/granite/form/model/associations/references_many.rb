module Granite
  module Form
    module Model
      module Associations
        class ReferencesMany < ReferencesAny
          def target=(object)
            loaded!
            @target = object.to_a
          end

          def load_target
            source = read_source
            source.present? ? reflection.persistence_adapter.find_all(owner, source) : default
          end

          def default
            return [] if evar_loaded?

            default = Array.wrap(reflection.default(owner))

            return [] unless default

            if default.all? { |object| object.is_a?(reflection.persistence_adapter.data_type) }
              default
            elsif default.all? { |object| object.is_a?(Hash) }
              default.map { |attributes| build_object(attributes) }
            else
              reflection.persistence_adapter.find_all(owner, default)
            end || []
          end

          def reader(force_reload = false)
            reload if force_reload
            @proxy ||= reflection.persistence_adapter.referenced_proxy(self)
          end

          def replace(objects)
            loaded!
            transaction do
              clear
              append objects
            end
          end

          alias writer replace

          def concat(*objects)
            append objects.flatten
            reader
          end

          def clear
            attribute.pollute do
              write_source([])
            end
            reload.empty?
          end

          def identify
            target.map { |obj| reflection.persistence_adapter.identify(obj) }
          end

          private

          def append(objects)
            attribute.pollute do
              objects.each do |object|
                next if target.include?(object)

                raise_type_mismatch(object) unless matches_type?(object)

                target.push(object)
                write_source(identify)
              end
            end
            target
          end
        end
      end
    end
  end
end
