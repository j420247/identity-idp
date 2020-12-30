# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

img_src = [
  :self,
  :data,
  'login.gov',
  AppConfig.env.asset_host,
  'idscangoweb.acuant.com',
  AppConfig.env.aws_region && "https://s3.#{AppConfig.env.aws_region}.amazonaws.com",
].select(&:present?)



script_src = SecureHeadersWhitelister.script_src
connect_src = SecureHeadersWhitelister.connect_src

style_src =  if !Rails.env.production?
               [:self, :unsafe_inline]
             else
               [:self, AppConfig.env.asset_host]
             end
font_src = [:self, :data, AppConfig.env.asset_host].select(&:present?)
style_src = [:self, AppConfig.env.asset_host].select(&:present?)

Rails.application.config.content_security_policy do |policy|
  policy.default_src :self
  policy.font_src    *font_src
  policy.img_src     *img_src
  policy.object_src  :none
  policy.script_src  *script_src
  policy.style_src   *style_src
  policy.connect_src *connect_src

  # Specify URI for violation reports
  # policy.report_uri "/csp-violation-report-endpoint"
end

Rails.application.config.content_security_policy_nonce_generator = -> request { SecureRandom.base64(16) }

# If you are using UJS then enable automatic nonce generation
# Rails.application.config.content_security_policy_nonce_generator = -> request { SecureRandom.base64(16) }

# Set the nonce only to specific directives
# Rails.application.config.content_security_policy_nonce_directives = %w(script-src)

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
# Rails.application.config.content_security_policy_report_only = true
