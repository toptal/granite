require 'memoist'
require 'action_controller/metal/exceptions'

class Granite::Dispatcher
  extend Memoist

  # Make dispatcher object pristine, clean memoist cache.
  def reset!
    unmemoize_all
  end

  def call(*)
    # Pretend to be a Rack app, however we are still dispatcher, so this method should never be called
    # see lib/granite/routing/mapping.rb for more info.
    fail 'Dispatcher can\'t be used as a Rack app.'
  end

  def serve(req)
    controller, action = detect_controller_class_and_action_name(req)
    controller.action(action).call(req.env)
  end

  def constraints
    [->(req) { detect_controller_class_and_action_name(req).all?(&:present?) }]
  end

  def controller(params, *_args)
    projector(*params.values_at(:granite_action, :granite_projector))&.controller_class
  end

  def prepare_params!(params, *_args)
    params
  end

  private

  def detect_controller_class_and_action_name(req)
    [
      controller(req.params),
      action_name(
        req.request_method_symbol,
        *req.params.values_at(:granite_action, :granite_projector, :projector_action)
      )
    ]
  end

  memoize def action_name(request_method_symbol, granite_action, granite_projector, projector_action)
    projector = projector(granite_action, granite_projector)
    return unless projector

    projector.action_for(request_method_symbol, projector_action.to_s)
  end

  memoize def projector(granite_action, granite_projector)
    action = business_action(granite_action)

    action.public_send(granite_projector) if action.respond_to?(granite_projector)
  end

  memoize def business_action(granite_action)
    granite_action.camelize.safe_constantize ||
      fail(ActionController::RoutingError, "Granite action '#{granite_action}' is mounted but class '#{granite_action.camelize}' can't be found")
  end
end
