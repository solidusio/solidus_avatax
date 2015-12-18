# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)

require "rspec/rails"

require "database_cleaner"
require "ffaker"

require "spree/testing_support/factories"
require "spree/testing_support/controller_requests"
require "spree/testing_support/authorization_helpers"
require "spree/testing_support/url_helpers"

require 'spree_avatax/factories'

require 'avatax_taxservice'
require 'hashie'
require 'vcr'

Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each { |f| require f }

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.filter_sensitive_data("[Username]") { ENV["AVATAX_USERNAME"] }
  c.filter_sensitive_data("[Password]") { ENV["AVATAX_PASSWORD"] }
  c.filter_sensitive_data("[Company]") { ENV["AVATAX_COMPANY_CODE"] }
end

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.mock_with :rspec

  config.color = true
  config.order = "random"

  config.expose_current_running_example_as :example
  config.fail_fast = ENV["FAIL_FAST"] || false

  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.use_transactional_fixtures = false

  config.include FactoryGirl::Syntax::Methods
  config.include Spree::TestingSupport::ControllerRequests, type: :controller
  config.include Spree::TestingSupport::UrlHelpers, type: :controller

  config.include ActionView::Helpers::TagHelper
  config.include ActionView::Context
  config.include SalesInvoiceSoapResponses
  config.include ReturnInvoiceSoapResponses

  # Ensure Suite is set to use transactions for speed.
  config.before :suite do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with :truncation
  end

  # Before each spec check if it is a Javascript test and switch between using database transactions or not where necessary.
  config.before :each do
    DatabaseCleaner.strategy = example.metadata[:js] ? :truncation : :transaction
    DatabaseCleaner.start

    FactoryGirl.create(:tax_rate, calculator: create(:avatax_tax_calculator))
  end

  # After each spec clean the database.
  config.after :each do
    DatabaseCleaner.clean
  end
end
