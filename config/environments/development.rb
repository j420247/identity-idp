Rails.application.configure do
  # Verifies that versions and hashed value of the package contents in the project's package.json
  config.webpacker.check_yarn_integrity = true

  config.cache_classes = false
  config.eager_load = false
  config.consider_all_requests_local = true
  config.active_support.deprecation = :log
  config.active_record.migration_error = :page_load
  config.assets.debug = true
  config.assets.digest = true
  config.assets.raise_runtime_errors = true
  config.i18n.raise_on_missing_translations = true

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Annotate rendered view with file names.
  config.action_view.annotate_rendered_view_with_filenames = true

  config.action_mailer.default_url_options = {
    host: AppConfig.env.domain_name,
    protocol: 'http',
  }
  config.action_mailer.asset_host = AppConfig.env.mailer_domain_name
  config.action_mailer.smtp_settings = { address: ENV['SMTP_HOST'] || 'localhost', port: 1025 }

  config.lograge.enabled = true
  config.lograge.ignore_actions = ['Users::SessionsController#active']
  config.lograge.formatter = Lograge::Formatters::Json.new

  if Rails.root.join('tmp', 'caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}",
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Override log formatter
  config.log_formatter = Upaya::DevelopmentUpayaLogFormatter.new

  # Bullet gem config
  config.after_initialize do
    Bullet.enable = true
    Bullet.alert = true
    Bullet.bullet_logger = true
    Bullet.rails_logger = true
  end
end
