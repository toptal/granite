module Granite
  module Form
    module Model
      module Associations
        class ReferencesOne < ReferencesAny
          def target=(object)
            loaded!
            @target = object
          end

          def load_target
            source = read_source
            source ? reflection.persistence_adapter.find_one(owner, source) : default
          end

          def default
            return if evar_loaded?

            default = reflection.default(owner)

            return unless default

            case default
            when reflection.persistence_adapter.data_type
              default
            when Hash
              build_object(default)
            else
              reflection.persistence_adapter.find_one(owner, default)
            end
          end

          def reader(force_reload = false)
            reset if force_reload
            target
          end

          def replace(object)
            raise_type_mismatch(object) unless object.nil? || matches_type?(object)

            transaction do
              attribute.pollute do
                self.target = object
                write_source identify
              end
            end

            target
          end

          alias writer replace

          def identify
            reflection.persistence_adapter.identify(target)
          end
        end
      end
    end
  end
end
