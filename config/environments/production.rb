# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true

# don't run File.stat for every template on every request!
config.action_view.cache_template_loading = true

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors if you bad email addresses should just be ignored
# config.action_mailer.raise_delivery_errors = false

ActionMailer::Base.smtp_settings = {
}

require 'socket'
require 'pathname'

HOST_NUM = Socket.gethostname[4..-1].to_i

STATIC_IMAGE_DIR = Pathname.new('/var/jyte/static')
