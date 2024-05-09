RSpec.describe Granite, type: :request do
  extend Granite::ProjectorHelpers::ClassMethods

  before do
    stub_class(:projector, Granite::Projector) do
      get :confirm do
        render plain: 'OK'
      end

      post :perform
    end

    stub_class(:action, Granite::Action) do
      allow_if do
        raise 'No Performer' unless performer

        performer.id == 'User'
      end

      projector :dummy, class_name: 'Projector'
    end
  end

  draw_routes do
    resources :students do
      granite 'action#dummy', on: :collection
    end
  end

  describe '#authorize_action!' do
    before do
      allow(Granite::Form.config.logger).to receive(:info)
    end

    context 'without performer' do
      it 'is not allowed' do
        get '/students/action/confirm'

        expect(request.env['action_dispatch.exception'].to_s).to eq('No Performer')
        expect(response).to have_http_status :internal_server_error
      end
    end

    context 'with user as project_performer' do
      let(:performer) { instance_double(User, id: 'User') }

      it 'is allowed' do
        allow_any_instance_of(ApplicationController).to receive(:projector_context).and_return(performer: performer) # rubocop:disable RSpec/AnyInstance

        get '/students/action/confirm'

        expect(request.env['action_dispatch.exception'].to_s).to eq('')
        expect(response).to be_successful
        expect(response.body).to eq 'OK'
      end
    end

    context 'with guest as project_performer' do
      let(:performer) { instance_double(User, id: 'Guest') }

      it 'is not allowed' do
        allow_any_instance_of(ApplicationController).to receive(:projector_context).and_return(performer: performer) # rubocop:disable RSpec/AnyInstance

        get '/students/action/confirm'

        expect(request.env['action_dispatch.exception'].to_s).to eq('')
        expect(response).to have_http_status :forbidden
        expect(response.body).to match(/Action action is not allowed for (.*)Guest/)
      end
    end
  end
end
