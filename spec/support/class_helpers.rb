module ClassHelpers
  def stub_model_class(name, superclass = nil, &block)
    stub_class(name, superclass || ApplicationRecord, &block)
  end

  def stub_class(name, superclass = nil, &block)
    context = self
    stub_const(name.to_s.camelize, Class.new(superclass || Object)).tap do |klass|
      # The name of a class is set by the interpreter when the class object is
      # first assigned to a constant. For example, in
      #
      #   c = Class.new
      #   C = c
      #
      # the class in the c variable is anonymous at first, and it is after the
      # second line that the interpreter sets the name to "C" as a side-effect
      # of the constant assignment.
      #
      # If we passed the block to stub_const, the class would be still anonymous
      # while the block is executed. This is not convenient for the typical use
      # cases of this method, because if an anonymous class is fine you do not
      # need to stub a constant, Class.new would be enough.
      #
      # So, we get the constant assignment first with stub_const, and then the
      # block is eval'ed with the class name already in place.
      #
      # Also, you can pass self as a block argument. Example:
      #
      # let(:a) { 1 }
      # ...
      # stub_class(:my_super_class) do |context|
      #   define_method(:a)
      #     context.a
      #   end
      # end
      #
      # MySuperClass.new.a => 1
      #
      # Please be sure that you aren't using keywords like `def` or `class`
      # because they will change the scope and you won't be able to get
      # an access to variables created by `let`.
      # Use `define_method` or `Class.new` instead
      klass.class_exec(context, &block) if block_given?
    end
  end
end

RSpec.configuration.include ClassHelpers
