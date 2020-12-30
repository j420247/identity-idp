module PivCacConcern
  extend ActiveSupport::Concern

  include SecureHeadersConcern

  def create_piv_cac_nonce
    piv_session[:piv_cac_nonce] = SecureRandom.base64(20)
  end

  def piv_cac_nonce
    piv_session[:piv_cac_nonce]
  end

  def clear_piv_cac_nonce
    piv_session.delete(:piv_cac_nonce)
  end

  def save_piv_cac_information(data)
    piv_session[:decrypted_x509] = data.to_json
  end

  def clear_piv_cac_information
    piv_session.delete(:decrypted_x509)
  end

  def piv_session
    user_session || session
  end

  def set_piv_cac_setup_csp_form_action_uris
    self.class.content_security_policy do |p|
      p.form_action -> { piv_cac_setup_csp_form_action_uris }
    end
  end

  def piv_cac_setup_csp_form_action_uris
    # PIV/CAC setup redirects to the PIV/CAC service to validate a CAC.
    # If user is setting up PIV/CAC as a second MFA after personal key
    # retirement they can also be redirected to the SP. Thusly the redirect URI
    # for the SP and for the PIV/CAC service need appear in the CSP form-action
    # Returns fully formed CSP array w/"'self'" and redirect_uris
    piv_cac_uri = if Rails.env.development?
                    AppConfig.env.piv_cac_service_url
                  else
                    "https://*.pivcac.#{LoginGov::Hostdata.env}.#{LoginGov::Hostdata.domain}"
                  end
    [piv_cac_uri] + csp_uris
  end
end
