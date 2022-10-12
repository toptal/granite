module Granite
  class Action
    class SubjectNotFoundError < ArgumentError
      def initialize(action_class)
        super "Unable to initialize #{action_class} without subject provided"
      end
    end

    class SubjectTypeMismatchError < ArgumentError
      def initialize(action_class, candidate, expected)
        super "Unable to initialize #{action_class} with #{candidate} as subject, expecting instance of #{expected}"
      end
    end

    module Subject
      extend ActiveSupport::Concern

      included do
        class_attribute :_subject
      end

      module ClassMethods
        def subject(name, *args, &block)
          reflection = reflect_on_association(name)
          reflection ||= references_one name, *args, &block

          alias_association :subject, reflection.name
          alias_attribute :id, reflection.reference_key

          self._subject = name
        end

        def subject?
          _subject.present?
        end
      end

      def initialize(*args)
        unless self.class.subject?
          super
          return
        end

        reflection = find_subject_reflection
        attributes = extract_initialize_attributes(args)

        subject_attributes = extract_subject_attributes!(attributes, reflection)
        assign_subject(args, subject_attributes, reflection)

        super attributes
      end

      private

      def find_subject_reflection
        self.class.reflect_on_association(self.class._subject)
      end

      def extract_initialize_attributes(args)
        if args.last.respond_to?(:to_unsafe_hash)
          args.pop.to_unsafe_hash
        else
          args.extract_options!
        end.symbolize_keys
      end

      def assign_subject(args, attributes, reflection)
        assign_attributes(attributes)

        self.subject = args.first unless args.empty?
        fail SubjectNotFoundError, self.class unless subject
      rescue ActiveData::AssociationTypeMismatch
        raise SubjectTypeMismatchError.new(self.class, args.first.class.name, reflection.klass)
      end

      def extract_subject_attributes!(attributes, reflection)
        attributes.extract!(:subject, :id, reflection.name, reflection.reference_key)
      end
    end
  end
end
