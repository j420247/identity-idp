module Idv
  module Steps
    class SendLinkStep < DocAuthBaseStep
      def call
        return failure(I18n.t('errors.doc_auth.send_link_throttle')) if throttled_else_increment
        telephony_result = send_link
        return failure(telephony_result.error.friendly_message) unless telephony_result.success?
      end

      private

      def send_link
        session_uuid = flow_session[:document_capture_session_uuid]
        update_document_capture_session_requested_at(session_uuid)
        Telephony.send_doc_auth_link(
          to: formatted_destination_phone,
          link: link(session_uuid),
        )
      end

      def form_submit
        Idv::PhoneForm.new(previous_params: {}, user: current_user).submit(permit(:phone))
      end

      def formatted_destination_phone
        raw_phone = permit(:phone)[:phone]
        PhoneFormatter.format(raw_phone, country_code: 'US')
      end

      def update_document_capture_session_requested_at(session_uuid)
        document_capture_session = DocumentCaptureSession.find_by(uuid: session_uuid)
        return unless document_capture_session
        document_capture_session.update!(
          requested_at: Time.zone.now,
          issuer: sp_session[:issuer],
          ial2_strict: sp_session[:ial2_strict],
        )
      end

      def link(session_uuid)
        idv_capture_doc_dashes_url('document-capture-session': session_uuid)
      end

      def throttled_else_increment
        Throttler::IsThrottledElseIncrement.call(user_id, :idv_send_link)
      end
    end
  end
end
