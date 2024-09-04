module Granite
  module Form
    module Model
      module Associations
        class EmbedsMany < EmbedsAny
          def build(attributes = {})
            push_object(build_object(attributes))
          end

          def target=(objects)
            objects.each { |object| setup_performers! object }
            loaded!
            @target = objects
          end

          def load_target
            source = read_source
            source.present? ? reflection.klass.instantiate_collection(source) : default
          end

          def default
            unless evar_loaded?
              default = Array.wrap(reflection.default(owner))
              if default.present?
                collection = if default.all? { |object| object.is_a?(reflection.klass) }
                               default
                             else
                               default.map do |attributes|
                                 reflection.klass.with_sanitize(false) do
                                   build_object(attributes)
                                 end
                               end
                             end
                collection.map { |object| object.send(:clear_changes_information) } if reflection.klass.dirty?
                collection
              end
            end || []
          end

          def reset
            super
            @target = []
          end

          def sync
            write_source(target.map { |model| model_data(model) })
          end

          def clear
            target
            @target = []
            true
          end

          def reader(force_reload = false)
            reload if force_reload
            @proxy ||= Collection::Embedded.new self
          end

          def replace(objects)
            transaction do
              clear
              append(objects)
            end
          end

          alias writer replace

          def concat(*objects)
            append objects.flatten
          end

          private

          def read_source
            super || []
          end

          def append(objects)
            objects.each do |object|
              unless object.is_a?(reflection.klass)
                raise AssociationTypeMismatch.new(reflection.klass,
                                                  object.class)
              end

              push_object object
            end
            target
          end

          def push_object(object)
            setup_performers! object
            target[target.size] = object
            object
          end

          def setup_performers!(object)
            embed_object(object)
            callback(:before_add, object)

            callback(:after_add, object)
          end
        end
      end
    end
  end
end
