require File.expand_path('../boot', __FILE__)

require 'rails/all'
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "active_resource/railtie"
require "rails/test_unit/railtie"
require "./lib/util/boot_util"

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
require 'apipie-rails' # FIXME will be removed after https://github.com/Pajk/apipie-rails/pull/62

if defined?(Bundler)
  Bundler.require(:default, Rails.env)
  
  # require backend engines only if in katello/cfse mode
  Bundler.require(:foreman) if Katello::BootUtil.katello?
end

module Src
  class Application < Rails::Application    
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(#{Rails.root}/lib)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    #config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    #config.i18n.default_locale = :en

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)
    config.action_view.javascript_expansions[:defaults] = ['jquery-1.4.2', 'jquery.ui-1.8.1/jquery-ui-1.8.1.custom.min', 'jquery-ujs/rails']

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]
    
    config.generators do |g|
      g.test_framework :rspec
      g.template_engine :haml
    end

    # Load the katello.yml.  Details from it are used in setting some config elements of the environment.
    katello_config = YAML.load_file('/etc/katello/katello.yml') rescue nil
    if katello_config.nil?
      katello_config = YAML.load_file("#{Rails.root}/config/katello.yml") rescue nil
    end

    # Configure the mailer.
    config.action_mailer.delivery_method = :sendmail
    config.action_mailer.perform_deliveries = true
    config.action_mailer.raise_delivery_errors = true

    host = "127.0.0.1" # default
    protocol = "http"  # default
    port = nil
    unless katello_config['common'].nil?
      host = katello_config['common']['host'] unless katello_config['common']['host'].nil?
      port = katello_config['common']['port'].to_s unless katello_config['common']['port'].nil?
      unless katello_config['common']['use_ssl'].nil?
        if katello_config['common']['use_ssl']
          protocol = "https"
        end
      end
    end
    prefix = ENV['RAILS_RELATIVE_URL_ROOT'] || '/'
    if (port.nil?)
      config.action_mailer.default_url_options = {:host => host + prefix, :protocol => protocol}
    else
      config.action_mailer.default_url_options = {:host => host + ':' + port + prefix, :protocol => protocol}
    end

    config.after_initialize do
      require 'monkeys/fix_string_interpolate'
      require "string"
    end


    # set actions to profile (eg. %w(user_sessions#new))
    # profiles will be stored in tmp/profiles/
    config.do_profiles = []

    # if paranoia is set to true even children of Exception will be rescued
    config.exception_paranoia = false
  end
end

old_fast_gettext = !defined?(FastGettext::Version) ||
    FastGettext::Version.split('.').map(&:to_i).zip([0, 6, 8]).any? { |a, b| a < b }

FastGettext.add_text_domain('app', { :path => 'locale', :type => :po, :ignore_fuzzy => true }.
    update(old_fast_gettext ? { :ignore_obsolete => true } : { :report_warning => false }))

FastGettext.default_text_domain = 'app'
