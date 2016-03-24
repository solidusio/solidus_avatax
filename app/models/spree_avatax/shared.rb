module SpreeAvatax::Shared
  class FailedApiResponse < StandardError
    attr_reader :response, :messages

    def initialize(response)
      @response = response
      # avatax seems to have two different error message formats:
      # https://gist.github.com/jordan-brough/a22163e4551c692365b8
      # https://gist.github.com/jordan-brough/c778a3417850dfa2307c
      # We should pester Avatax about this sometime.
      if @response[:messages].is_a?(Array)
        @messages = response[:messages]
      else
        @messages = Array.wrap(response[:messages][:message])
      end

      super(messages.map { |msg| msg[:summary] })
    end
  end

  class << self

    def taxable_order?(order)
      order.line_items.present? && order.ship_address.present?
    end

    def get_tax(params)
      call_tax_svc_with_timeout(:gettax, params)
    end

    def post_tax(params)
      call_tax_svc_with_timeout(:posttax, params)
    end

    def cancel_tax(params)
      call_tax_svc_with_timeout(:canceltax, params)
    end

    def tax_svc
      @tax_svc ||= AvaTax::TaxService.new({
        username:               SpreeAvatax::Config.username,
        password:               SpreeAvatax::Config.password,
        service_url:            SpreeAvatax::Config.service_url,
        clientname:             'Spree::Avatax',
      })
    end

    # We looked at the code in the AvaTax gem and using timeout here seems safe.
    def call_tax_svc_with_timeout(method, *args)
      Timeout.timeout(SpreeAvatax::Config.timeout, SpreeAvatax::AvataxTimeout) do
        tax_svc.public_send(method, *args)
      end
    end

    def require_success!(response)
      if response[:result_code] == 'Success'
        Rails.logger.info "[avatax] response - result=success doc_id=#{response[:doc_id]} doc_code=#{response[:doc_code]} transaction_id=#{response[:transaction_id]}"
        Rails.logger.debug { "[avatax] response: #{response.to_json}" }
      else
        Rails.logger.error "[avatax] response - result=error doc_id=#{response[:doc_id]} doc_code=#{response[:doc_code]} transaction_id=#{response[:transaction_id]}"
        Rails.logger.error "[avatax] response: #{response.to_json}"
        raise FailedApiResponse.new(response)
      end
    end

  end

end
