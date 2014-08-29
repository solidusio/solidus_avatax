module SpreeAvatax
  class Config
    class << self
      attr_accessor :username
      attr_accessor :password
      attr_accessor :company_code
      attr_accessor :use_production_account
      # error_handler should be an object that responds to "call" and accepts an exception as an
      # argument.  If it is set then "generate" and "commit" errors will call error_handler instead
      # of raising.  This allows you to ignore certain errors or handle them in specific ways.
      attr_accessor :error_handler
    end

    self.use_production_account = false
  end
end
