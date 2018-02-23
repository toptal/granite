class BA::User::Create < BaseAction
  allow_if { false }

  precondition do
  end

  def subject
    @subject ||= User.new
  end

  private

  def execute_perform!(*)
    subject.save!
  end
end
