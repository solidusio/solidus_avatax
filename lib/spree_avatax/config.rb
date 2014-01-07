module SpreeAvatax
  class Config
    class << self
      attr_accessor :username
      attr_accessor :password
      attr_accessor :company_code
      attr_accessor :endpoint
      attr_accessor :suppress_api_errors

      def suppress_api_errors?
        suppress_api_errors
      end
    end
  end
end
