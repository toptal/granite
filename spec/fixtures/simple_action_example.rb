class User::Create < User::BusinessAction
  projector :simple

  allow_if { false }

  precondition do
  end

  private

  def execute_perform!(*)
    subject.save!
  end
end
