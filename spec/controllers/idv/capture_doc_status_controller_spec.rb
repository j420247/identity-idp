require 'rails_helper'

describe Idv::CaptureDocStatusController do
  let(:user) { build(:user) }

  before do
    stub_sign_in(user) if user
  end

  describe '#show' do
    let(:document_capture_session) { DocumentCaptureSession.create! }
    let(:flow_session) { { document_capture_session_uuid: document_capture_session.uuid } }

    before do
      allow_any_instance_of(Flow::BaseFlow).to receive(:flow_session).and_return(flow_session)
      controller.user_session['idv/doc_auth'] = flow_session if user
    end

    context 'when unauthenticated' do
      let(:user) { nil }

      it 'redirects to the root url' do
        get :show

        expect(response).to redirect_to root_url
      end
    end

    context 'when session does not exist' do
      let(:flow_session) { {} }

      it 'returns unauthorized' do
        get :show

        expect(response.status).to eq(401)
        expect(response.body).to eq('Unauthorized')
      end
    end

    context 'when result is pending' do
      it 'returns pending result' do
        get :show

        expect(response.status).to eq(202)
        expect(response.body).to eq('Pending')
      end
    end

    context 'when capture failed' do
      before do
        allow(EncryptedRedisStructStorage).to receive(:load).and_return(
          DocumentCaptureSessionResult.new(
            id: SecureRandom.uuid,
            success: false,
            pii: {},
          ),
        )
      end

      it 'returns unauthorized' do
        get :show

        expect(response.status).to eq(401)
        expect(response.body).to eq('Unauthorized')
      end
    end

    context 'when capture succeeded' do
      before do
        allow(EncryptedRedisStructStorage).to receive(:load).and_return(
          DocumentCaptureSessionResult.new(
            id: SecureRandom.uuid,
            success: true,
            pii: {},
          ),
        )
      end

      it 'returns success' do
        get :show

        expect(response.status).to eq(200)
        expect(response.body).to eq('Complete')
      end
    end
  end
end
