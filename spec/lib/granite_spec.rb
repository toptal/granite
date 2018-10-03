RSpec.describe Granite, type: :request do
  extend Granite::ProjectorHelpers::ClassMethods

  before do
    stub_class(:projector, Granite::Projector) do
      get :confirm do
        render plain: 'OK'
      end

      post :perform do
      end
    end

    stub_class(:action, Granite::Action) do
      allow_if do
        fail 'No Performer' unless performer

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
      allow(ActiveData.config.logger).to receive(:info)
    end

    context 'without performer' do
      it 'is not allowed' do
        get '/students/action/confirm'

        expect(request.env['action_dispatch.exception'].to_s).to eq('No Performer')
        expect(response.status).to eq 500
      end
    end

    context 'with project_performer' do
      context 'when user' do
        let(:performer) { OpenStruct.new(id: 'User') }

        it 'is allowed' do
          expect_any_instance_of(ApplicationController).to receive(:projector_performer).and_return(performer)

          get '/students/action/confirm'

          expect(request.env['action_dispatch.exception'].to_s).to eq('')
          expect(response).to be_successful
          expect(response.body).to eq 'OK'
        end
      end

      context 'when guest' do
        let(:performer) { OpenStruct.new(id: 'Guest') }

        it 'is not allowed' do
          expect_any_instance_of(ApplicationController).to receive(:projector_performer).and_return(performer)

          get '/students/action/confirm'

          expect(request.env['action_dispatch.exception'].to_s).to eq('')
          expect(response.status).to eq 403
          expect(response.body).to eq 'Action action is not allowed for OpenStruct#Guest'
        end
      end
    end
  end
end
