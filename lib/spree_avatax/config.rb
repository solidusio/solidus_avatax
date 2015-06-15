module SpreeAvatax
  class Config
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
    end
  end
end
