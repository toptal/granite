require 'rubocop'

module RuboCop
  module Cop
    module Granite

      # Checks if performer is being passed to the BA initializer.
      #
      # Instead of initializing, use `.as(performer)`
      #
      # @example
      #   # bad
      #   BA::Subject::Action.new(performer: current_role, other: 'arg')
      #
      #   # good
      #   BA::Subject::Action.as(current_role).new(other: 'arg')
      #
      #   # bad
      #   BA::Subject::Action.new(subject, performer: subject.author, other: 'arg')
      #
      #   # good
      #   BA::Subject::Action.as(subject.author).new(subject, other: 'arg')
      class PerformerInInitializer < ::RuboCop::Cop::Cop
        MSG = 'Use `.as(performer)` instead of passing performer to the initializer'.freeze

        def on_send(node)
          return unless business_action?(node) || testing_ba?(node)

          add_offense(node, location: :expression, message: MSG)
        end

        def autocorrect(node)
          return if has_method_calls_before_new?(node)

          node = described_class_initialized?(node).parent if testing_ba?(node)
          autocorrect_performer_as_expression(node)
        end

        private

        def_node_search :under_ba_namespace?, '(:const nil? :BA)'
        def_node_matcher :described_class_initialized?, '^(send (send _ :described_class) :new $_)'
        def_node_matcher :describe_block?, '(block (send _ :describe $...) ...)'
        def_node_search :has_performer_key_in_params?, '(sym :performer)'
        def_node_search :has_as_expression?, ' (send  _  :as _) '
        def_node_search :has_performer_as_role, '(pair #has_performer_key_in_params? (send _ :system))'
        def_node_search :has_performer_as_expression, '(pair #has_performer_key_in_params? $_)'
        def_node_matcher :has_method_calls_before_new?, '(send (send ...) :new ...)'

        def business_action?(node)
          return unless initializer?(node)
          return unless has_performer_key_in_params?(node)

          under_ba_namespace?(node) && !already_fixed?(node)
        end

        def already_fixed?(node)
          has_as_expression?(node)
        end

        def testing_ba?(node)
          return false unless described_class_is_ba?(node)

          params = described_class_initialized?(node)
          params && has_performer_key_in_params?(params)
        end

        def described_class_is_ba?(node)
          node.each_ancestor do |ancestor|
            describing_class = describe_block?(ancestor)
            if describing_class
              return false if describing_class.empty?

              return under_ba_namespace?(describing_class.first)
            end
          end
          false
        end

        def initializer?(node)
          node.type == :send && node.method_name == :new
        end

        def autocorrect_performer_as_expression(node)
          params, performer_param_pair = params_and_performer_pair_expression(node)
          performer_injection = "as(#{performer_param_pair.source})."
          autocorrect_performer(node, performer_injection, params, performer_param_pair)
        end

        def autocorrect_performer(node, performer_injection, params, performer_param_pair)
          lambda do |corrector|
            position = node.loc
            corrector.insert_before(position.selector, performer_injection)
            reject_performer_pair(corrector, params, performer_param_pair)
          end
        end

        def reject_performer_pair(corrector, params, performer_param_pair)
          performer_param_i = performer_param_index(params)
          return unless performer_param_i

          if params.children.size == 1
            remove_full_parameters(corrector, params, performer_param_pair) && return
          end

          if performer_param_i < params.children.size - 1
            remove_all_from_performer_param_until_next_param(performer_param_i, params, corrector)
          else
            remove_performer_param_only(performer_param_i, params, corrector)
          end
        end

        def performer_param_index(params)
          params.children.find_index { |pair| pair.children.first.children.first == :performer }
        end

        def remove_all_from_performer_param_until_next_param(performer_param_i, params, corrector)
          performer_param = params.children[performer_param_i]
          next_param = params.children[performer_param_i + 1]

          begin_pos = performer_param.loc.expression.begin_pos
          end_pos = next_param.loc.expression.begin_pos

          remove_in_range(corrector, begin_pos, end_pos)
        end

        def remove_performer_param_only(performer_param_i, params, corrector)
          performer_param = params.children[performer_param_i]
          prev_param = params.children[performer_param_i - 1]

          begin_pos = prev_param.loc.expression.end_pos
          end_pos = performer_param.loc.expression.end_pos

          remove_in_range(corrector, begin_pos, end_pos)
        end

        def remove_in_range(corrector, begin_pos, end_pos)
          buffer = processed_source.buffer
          range = Parser::Source::Range.new(buffer, begin_pos, end_pos)
          corrector.remove(range)
        end

        def params_and_performer_pair_expression(node)
          has_performer_as_expression(node) do |performer_param_pair|
            params = performer_param_pair.parent.parent
            return params, performer_param_pair
          end
        end

        def params_and_performer_pair_role(node)
          has_performer_as_role(node) do |performer_param_pair|
            params = performer_param_pair.parent
            return params, performer_param_pair
          end
        end

        def remove_full_parameters(corrector, params, performer_param_pair)
          if perform_merge_on_param_hash?(params)
            corrector.replace params.loc.expression, '{}'
          else
            corrector.remove params.loc.expression
            prev_sibling = previous_sibling(params)
            corrector.remove range_between(prev_sibling, performer_param_pair) if prev_sibling.respond_to? :loc
          end
        end

        def perform_merge_on_param_hash?(params)
          params.parent.type == :send && params.parent.children.include?(:merge)
        end

        def range_between(previous, node)
          buffer = processed_source.buffer
          begin_pos = previous.loc.expression.end_pos
          end_pos = node.loc.expression.begin_pos
          Parser::Source::Range.new(buffer, begin_pos, end_pos)
        end

        def previous_sibling(node)
          node_index = node.parent.children.index(node)
          node.parent.children[node_index - 1]
        end
      end
    end
  end
end
