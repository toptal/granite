module Granite
  module Form
    module Model
      module Associations
        module PersistenceAdapters
          class Base
            attr_reader :data_source, :primary_key, :scope_proc

            def initialize(data_source, primary_key, scope_proc = nil)
              @data_source = data_source
              @primary_key = primary_key
              @scope_proc = scope_proc
            end

            def build(_attributes)
              raise NotImplementedError,
                    'Should be implemented in inhereted adapter. Build new instance of data object by attributes'
            end

            def scope(_owner, _source)
              raise NotImplementedError, 'Should be implemented in inhereted adapter. Better to be Enumerable'
            end

            def find_one(owner, identificator)
              scope(owner, identificator).first
            end

            def find_all(owner, identificators)
              scope(owner, identificators).to_a
            end

            def identify(_object)
              raise NotImplementedError,
                    'Should be implemented in inhereted adapter. Field to be used as primary_key for object'
            end

            def data_type
              raise NotImplementedError,
                    'Should be implemented in inhereted adapter. Type of data object for type_check'
            end

            def primary_key_type
              raise NotImplementedError, 'Should be implemented in inhereted adapter. Ruby data type'
            end

            def referenced_proxy
              raise NotImplementedError,
                    'Should be implemented in inhereted adapter. Object to manage proxying of methods to scope.'
            end
          end
        end
      end
    end
  end
end
