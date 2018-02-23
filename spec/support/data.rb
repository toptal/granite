RSpec.shared_context 'with student data' do
  let(:passed_student) { Student.new(status: 'passed') }
  let(:failed_student) { Student.new(status: 'failed') }
end
