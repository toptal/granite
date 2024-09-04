module MuffleHelpers
  def muffle(*exceptions)
    yield
  rescue *exceptions.flatten
    nil
  end
end

RSpec.configuration.include MuffleHelpers
