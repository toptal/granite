module Granite
  module Form
    module Model
      module Associations
        module Collection
          class Proxy
            include Enumerable

            delegate :target, :loaded?, :reload, :clear, :concat, to: :@association
            delegate :each, :size, :length, :first, :last, :empty?, :many?, :==, :dup, to: :target
            alias << concat
            alias push concat

            def initialize(association)
              @association = association
            end

            def to_ary
              dup
            end

            alias to_a to_ary

            def inspect
              entries = target.take(10).map!(&:inspect)
              entries[10] = '...' if target.size > 10

              "#<#{self.class.name.demodulize} [#{entries.join(', ')}]>"
            end
          end
        end
      end
    end
  end
end
