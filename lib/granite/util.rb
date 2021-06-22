module Granite
  module Util
    extend ActiveSupport::Concern

    # Evaluates value and returns result based on what was passed:
    # - if Proc was passed, then executes it in context of self
    # - if Symbol was passed, then calls a method with that name and returns result
    # - otherwise just returns the value itself
    # @param value [Object] value to evaluate
    # @return [Object] result of evaluation
    def evaluate(value)
      case value
      when Proc
        evaluate_proc(value)
      when Symbol
        evaluate_symbol(value)
      else
        value
      end
    end

    # Evaluates `if` or `unless` conditions present in the supplied
    # `options` being it a symbol or callable.
    #
    # @param [Hash] options The method options to evaluate.
    # @option options :if method name or callable
    # @option options :unless method name or callable
    # @return [Boolean] whether conditions are satisfied
    def conditions_satisfied?(**options)
      fail ArgumentError, 'You cannot specify both if and unless' if options.key?(:if) && options.key?(:unless)

      if options.key?(:if)
        evaluate(options[:if])
      elsif options.key?(:unless)
        !evaluate(options[:unless])
      else
        true
      end
    end

    private

    def evaluate_proc(value)
      instance_exec(&value)
    end

    def evaluate_symbol(value)
      __send__(value)
    end
  end
end
