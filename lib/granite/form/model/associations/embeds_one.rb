module Granite
  module Form
    module Model
      module Associations
        class EmbedsOne < EmbedsAny
          def build(attributes = {})
            self.target = build_object(attributes)
          end

          def target=(object)
            if object
              callback(:before_add, object)
              setup_performers! object
            end
            loaded!
            @target = object
            callback(:after_add, object) if object
          end

          def load_target
            source = read_source
            source ? reflection.klass.instantiate(source) : default
          end

          def default
            return if evar_loaded?

            default = reflection.default(owner)

            return unless default

            object = if default.is_a?(reflection.klass)
                       default
                     else
                       reflection.klass.with_sanitize(false) do
                         build_object(default)
                       end
                     end
            object.send(:clear_changes_information) if reflection.klass.dirty?
            object
          end

          def sync
            write_source(model_data(target))
          end

          def clear
            target
            @target = nil
            true
          end

          def reader(force_reload = false)
            reload if force_reload
            target
          end

          def replace(object)
            if object
              raise AssociationTypeMismatch.new(reflection.klass, object.class) unless object.is_a?(reflection.klass)

              transaction do
                clear
                self.target = object
              end
            else
              clear
            end

            target
          end

          alias writer replace

          private

          def setup_performers!(object)
            embed_object(object)
          end
        end
      end
    end
  end
end
