module SpreeAvatax
  class Config < Spree::Base
    DEFAULT_TIMEOUT = 20

    class << self
      attr_accessor :username
      attr_accessor :password
      attr_accessor :company_code
      attr_accessor :service_url
      # These error handlers should be objects that respond to "call" and accept an order and an
      # exception as arguments.  This allows you to ignore certain errors or handle them in
      # specific ways.
      attr_accessor :sales_invoice_generate_error_handler
      attr_accessor :sales_invoice_commit_error_handler
      attr_accessor :sales_invoice_cancel_error_handler

      def timeout
        (config = last) ? config.timeout : DEFAULT_TIMEOUT
      end

      def enabled
        (config = last) ? config.enabled : true
      end
    end

    validates :enabled, inclusion: {in: [true, false]}
    validates :timeout, presence: true
  end
end
