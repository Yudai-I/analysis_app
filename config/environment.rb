# Load the Rails application.
require_relative "application"

require 'dotenv/load' if Rails.env.development? || Rails.env.test?

# Initialize the Rails application.
Rails.application.initialize!
