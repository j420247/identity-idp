module ApplicationHelper
  def title(title)
    content_for(:title) { title }
  end

  def background_cls(cls)
    content_for(:background_cls) { cls }
  end

  def step_class(step, active)
    if active > step
      'complete'
    elsif active == step
      'active'
    end
  end

  def sp_session
    session.fetch(:sp, {})
  end

  def user_signing_up?
    params[:confirmation_token].present? || (
      current_user && !MfaPolicy.new(current_user).two_factor_enabled?
    )
  end

  def session_with_trust?
    current_user || page_with_trust?
  end

  def page_with_trust?
    current_page?(controller: 'sign_up/passwords', action: 'new') ||
      current_page?(controller: 'users/reset_passwords', action: 'edit')
  end

  def ial2_requested?
    sp_session && sp_session[:ial2]
  end

  def user_verifying_identity?
    return unless current_user
    sp_session && sp_session[:ial2] && multiple_factors_enabled?
  end

  def liveness_checking_enabled?
    FeatureManagement.liveness_checking_enabled? &&
      (sp_session[:issuer].blank? || sp_session[:ial2_strict])
  end

  def sign_up_or_idv_no_js_link
    if user_signing_up?
      destroy_user_path
    elsif user_verifying_identity?
      idv_doc_auth_url
    end
  end

  def cancel_link_text
    if user_signing_up?
      t('links.cancel_account_creation')
    else
      t('links.cancel')
    end
  end

  def desktop_device?
    DeviceDetector.new(request.user_agent)&.device_type == 'desktop'
  end
end
