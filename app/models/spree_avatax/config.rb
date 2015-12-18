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

      # These configurations are stored in the database so that they can be
      # updated immediately and synchronously across all servers in the event of
      # an outage, without a redeploy or restart.
      def timeout
        (config = active) ? config.timeout : DEFAULT_TIMEOUT
      end

      def enabled
        (config = active) ? config.enabled : true
      end

      private

      def active
        order(:id).last
      end
    end

    validates :enabled, inclusion: {in: [true, false]}
    validates :timeout, presence: true
  end
end
