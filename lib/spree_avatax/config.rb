require 'avalara'

module SpreeAvatax
  class Config
    class << self

      [:username, :username=, :password, :password=, :endpoint, :endpoint=].each do |config|
        delegate config, to: ::Avalara
      end

      attr_accessor :company_code

      # the "use_production_account" config will replace the "endpoint" config soon
      attr_accessor :use_production_account
    end

    self.use_production_account = false
  end
end
