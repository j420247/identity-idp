require 'rails_helper'

feature 'doc auth send link step' do
  include IdvStepHelper
  include DocAuthHelper

  before do
    sign_in_and_2fa_user
    complete_doc_auth_steps_before_send_link_step
  end

  let(:idv_send_link_max_attempts) { AppConfig.env.idv_send_link_max_attempts.to_i }
  let(:idv_send_link_attempt_window_in_minutes) do
    AppConfig.env.idv_send_link_attempt_window_in_minutes.to_i
  end
  let(:document_capture_session) { DocumentCaptureSession.create! }

  it 'is on the correct page' do
    expect(page).to have_current_path(idv_doc_auth_send_link_step)
    expect(page).to have_content(t('doc_auth.headings.take_picture'))
  end

  it 'proceeds to the next page with valid info' do
    expect(Telephony).to receive(:send_doc_auth_link).
      with(hash_including(to: '+1 415-555-0199')).
      and_call_original

    fill_in :doc_auth_phone, with: '415-555-0199'
    click_idv_continue

    expect(page).to have_current_path(idv_doc_auth_link_sent_step)
  end

  it 'sends a link that does not contain any underscores' do
    # because URLs with underscores sometimes get messed up by carriers
    expect(Telephony).to receive(:send_doc_auth_link).and_wrap_original do |impl, config|
      expect(config[:link]).to_not include('_')

      impl.call(config)
    end

    fill_in :doc_auth_phone, with: '415-555-0199'
    click_idv_continue

    expect(page).to have_current_path(idv_doc_auth_link_sent_step)
  end

  it 'does not proceed to the next page with invalid info' do
    fill_in :doc_auth_phone, with: ''
    click_idv_continue

    expect(page).to have_current_path(idv_doc_auth_send_link_step)
  end

  it 'does not proceed if Telephony raises an error' do
    fill_in :doc_auth_phone, with: '225-555-1000'
    click_idv_continue

    expect(page).to have_current_path(idv_doc_auth_send_link_step)
    expect(page).to have_content I18n.t('telephony.error.friendly_message.generic')
  end

  it 'throttles sending the link' do
    user = sign_in_and_2fa_user
    idv_send_link_max_attempts.times do
      sign_in_and_2fa_user(user)
      complete_doc_auth_steps_before_send_link_step
      expect(page).to_not have_content I18n.t('errors.doc_auth.send_link_throttle')

      fill_in :doc_auth_phone, with: '415-555-0199'
      click_idv_continue

      expect(page).to have_current_path(idv_doc_auth_link_sent_step)
      click_on t('doc_auth.buttons.start_over')
    end

    sign_in_and_2fa_user(user)
    complete_doc_auth_steps_before_send_link_step
    fill_in :doc_auth_phone, with: '415-555-0199'
    click_idv_continue
    expect(page).to have_current_path(idv_doc_auth_send_link_step)
    expect(page).to have_content I18n.t('errors.doc_auth.send_link_throttle')

    Timecop.travel(Time.zone.now + idv_send_link_attempt_window_in_minutes.minutes) do
      fill_in :doc_auth_phone, with: '415-555-0199'
      click_idv_continue
      expect(page).to have_current_path(idv_doc_auth_link_sent_step)
    end
  end

  it 'includes expected URL parameters' do
    allow_any_instance_of(Flow::BaseFlow).to receive(:flow_session).and_return(
      document_capture_session_uuid: document_capture_session.uuid,
    )

    expect(Telephony).to receive(:send_doc_auth_link).and_wrap_original do |impl, config|
      params = Rack::Utils.parse_nested_query URI(config[:link]).query
      expect(params).to eq('document-capture-session' => document_capture_session.uuid)

      impl.call(config)
    end

    fill_in :doc_auth_phone, with: '415-555-0199'
    click_idv_continue
  end

  it 'sets requested_at on the capture session' do
    allow_any_instance_of(Flow::BaseFlow).to receive(:flow_session).and_return(
      document_capture_session_uuid: document_capture_session.uuid,
    )

    fill_in :doc_auth_phone, with: '415-555-0199'
    click_idv_continue

    document_capture_session.reload
    expect(document_capture_session).to have_attributes(requested_at: a_kind_of(Time))
  end
end
