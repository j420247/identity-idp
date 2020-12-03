module SessionTimeoutWarningHelper
  def frequency
    (AppConfig.env.session_check_frequency || 150).to_i
  end

  def start
    (AppConfig.env.session_check_delay || 30).to_i
  end

  def warning
    (AppConfig.env.session_timeout_warning_seconds || 30).to_i
  end

  def timeout_refresh_path
    UriService.add_params(
      request.original_fullpath,
      timeout: true,
    )&.html_safe # rubocop:disable Rails/OutputSafety
  end

  def auto_session_timeout_js
    javascript_tag nonce: true do
      render partial: 'session_timeout/ping',
             formats: [:js],
             locals: {
               warning: warning,
               start: start,
               frequency: frequency,
               modal: modal,
             }
    end
  end

  # rubocop:disable Rails/HelperInstanceVariable
  def auto_session_expired_js
    return if @skip_session_expiration

    session_timeout_in = Devise.timeout_in
    javascript_tag nonce: true do
      render(
        partial: 'session_timeout/expire_session',
        formats: [:js],
        locals: { session_timeout_in: session_timeout_in },
      )
    end
  end
  # rubocop:enable Rails/HelperInstanceVariable

  def time_left_in_session
    distance_of_time_in_words(warning)
  end

  def modal
    if user_fully_authenticated?
      FullySignedInModalPresenter.new(time_left_in_session)
    else
      PartiallySignedInModalPresenter.new(time_left_in_session)
    end
  end
end

ActionView::Base.send :include, SessionTimeoutWarningHelper
