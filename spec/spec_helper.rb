require "simplecov"
SimpleCov.start "rails"

#if ENV["CI"] == "true"
#  require "codecov"
#  SimpleCov.formatter = SimpleCov::Formatter::Codecov
#end

# This file is copied to spec/ when you run "rails generate rspec:install"
ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../../config/environment", __FILE__)
require "rspec/rails"
require "capybara-screenshot/rspec"
require "capybara/email/rspec"
require "database_cleaner/active_record"
#require "capybara/poltergeist"
# require "rspec/autorun"

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

Capybara.server = :puma, { Silent: true }

# /!\ Locally I sometimes need to run 'export TMPDIR="$HOME/tmp"' before calling 'rspec .', for javascript tests to run! /!\
# /!\ You need to create the folder $HOME/tmp for that command to work! /!\
Capybara.register_driver :selenium_firefox_headless do |app|
  options = Selenium::WebDriver::Firefox::Options.new
  options.args << '--headless'
  Capybara::Selenium::Driver.new(app, browser: :firefox, options: options)
end

Capybara.register_driver :selenium_firefox do |app|
  Capybara::Selenium::Driver.new(app, browser: :firefox)
end

Capybara.javascript_driver = :selenium_firefox_headless
# Looks like the following line does not work anymore... We added $.fx.off = true in application.html.erb to disable animations in test mode
Capybara.disable_animation = true # Otherwise we need to wait for rolling animations

#DatabaseCleaner.strategy = :truncation # Not sure if it should be used?

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you"re not using ActiveRecord or ActiveRecord fixtures
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you"re not using ActiveRecord, or you"d prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false # Need to set false when using DatabaseCleaner
  
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end
  
  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end
  
  config.before(:each, :js => true) do
    DatabaseCleaner.strategy = :truncation
  end
  
  config.before(:each) do
    DatabaseCleaner.start
  end
  
  config.after(:each) do
    DatabaseCleaner.clean
  end
  
  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"
  
  config.include CapybaraSelect2
  config.include ActiveSupport::Testing::TimeHelpers # To change the current time manually
  
  config.include Capybara::DSL
  
  config.include Rails.application.routes.url_helpers
  
  config.example_status_persistence_file_path = "tmp/examples.txt"
end


#Capybara::Webkit.configure do |config|
#  config.block_unknown_urls
#  config.debug = false
#end

