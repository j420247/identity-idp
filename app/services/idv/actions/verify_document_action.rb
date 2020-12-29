module Idv
  module Actions
    class VerifyDocumentAction < Idv::Steps::DocAuthBaseStep
      def call
        enqueue_job
      end

      private

      def form_submit
        response = form.submit
        presenter = ImageUploadResponsePresenter.new(
          form: form,
          form_response: response,
        )
        status = :accepted if response.success?
        render_json(
          presenter,
          status: status || presenter.status,
        )
        response
      end

      def form
        @form ||= Idv::ApiDocumentVerificationForm.new(
          params,
          liveness_checking_enabled: liveness_checking_enabled?,
        )
      end

      def enqueue_job
        verify_document_capture_session = create_document_capture_session(
          verify_document_capture_session_uuid_key,
        )
        verify_document_capture_session.requested_at = Time.zone.now
        verify_document_capture_session.create_doc_auth_session

        extra_log_info = if !%w[prod staging int].include?(LoginGov::Hostdata.env)
          {
            flow_session: flow_session.except(:pii_from_doc),
            flow_session_keys: flow_session.keys,
          }
        end

        @flow.analytics.track_event(
          Analytics::DOC_AUTH_ASYNC,
          info: 'creating document capture session',
          id: verify_document_capture_session.id,
          uuid: verify_document_capture_session.uuid,
          result_id: verify_document_capture_session.result_id,
          flow_session_key: flow_session[verify_document_capture_session_uuid_key],
          **extra_log_info.to_h,
        )

        callback_url = Rails.application.routes.url_helpers.document_proof_result_url(
          result_id: verify_document_capture_session.result_id,
        )

        LambdaJobs::Runner.new(
          job_class: Idv::Proofer.document_job_class,
          args: {
            encryption_key: params[:encryption_key],
            front_image_iv: params[:front_image_iv],
            back_image_iv: params[:back_image_iv],
            selfie_image_iv: params[:selfie_image_iv],
            front_image_url: params[:front_image_url],
            back_image_url: params[:back_image_url],
            selfie_image_url: params[:selfie_image_url],
            liveness_checking_enabled: liveness_checking_enabled?,
            callback_url: callback_url,
            trace_id: amzn_trace_id,
          },
        ).run do |doc_auth_result|
          document_result = doc_auth_result.to_h.fetch(:document_result, {})
          dcs = DocumentCaptureSession.new(result_id: verify_document_capture_session.result_id)
          dcs.store_doc_auth_result(
            result: document_result.except(:pii_from_doc),
            pii: document_result[:pii_from_doc],
          )

          nil
        end
      end
    end
  end
end
