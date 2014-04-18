require 'avalara'

module SpreeAvatax
  class Config
    class << self

      [:username, :username=, :password, :password=, :endpoint, :endpoint=].each do |config|
        delegate config, to: ::Avalara
      end

      attr_accessor :company_code
      attr_accessor :suppress_api_errors

      def suppress_api_errors?
        suppress_api_errors
      end
    end
  end
end
