module Granite
  module Form
    module Model
      module Dirty
        extend ActiveSupport::Concern

        ::Module.class_eval do
          alias_method :unconcerned_append_features, :append_features
        end

        DIRTY_CLONE = ActiveModel::Dirty.clone
        DIRTY_CLONE.class_eval do
          def self.append_features(base)
            unconcerned_append_features(base)
          end

          def self.included(_base); end
        end

        include DIRTY_CLONE

        included do
          attribute_names(false).each do |name|
            define_dirty name, generated_attributes_methods
          end
          _attribute_aliases.each_key do |name|
            define_dirty name, generated_attributes_methods
          end
        end

        if !method_defined?(:set_attribute_was) && !private_method_defined?(:set_attribute_was)
          private def set_attribute_was(attr, old_value)
            changed_attributes[attr] = old_value
          end
        end

        unless method_defined?(:clear_changes_information)
          if method_defined?(:reset_changes)
            def clear_changes_information
              reset_changes
            end
          else
            def clear_changes_information
              @previously_changed = nil
              @changed_attributes = nil
            end
          end
        end

        unless method_defined?(:_read_attribute)
          def _read_attribute(attr)
            __send__(attr)
          end
        end

        module ClassMethods
          def define_dirty(method, target = self)
            reflection = reflect_on_attribute(method)
            name = reflection ? reflection.name : method

            %w[changed? change will_change! was
               previously_changed? previous_change].each do |suffix|
              target.class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def #{method}_#{suffix}
                attribute_#{suffix} '#{name}'
              end
              RUBY
            end

            target.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def restore_#{method}!
              restore_attribute! '#{name}'
            end
            RUBY
          end

          def dirty?
            true
          end
        end
      end
    end
  end
end
