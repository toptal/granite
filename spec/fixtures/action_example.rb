class User::Create < User::BusinessAction
  allow_if { false }

  precondition do
  end

  private

  def execute_perform!(*)
    subject.save!
  end
end
