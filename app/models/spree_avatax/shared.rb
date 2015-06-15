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

    def logger
      Rails.logger
    end

    def taxable_order?(order)
      order.line_items.present? && order.ship_address.present?
    end

    def tax_svc
      @tax_svc ||= AvaTax::TaxService.new({
        username:               SpreeAvatax::Config.username,
        password:               SpreeAvatax::Config.password,
        service_url:            SpreeAvatax::Config.service_url,
        clientname:             'Spree::Avatax',
      })
    end

    def require_success!(response)
      if response[:result_code] == 'Success'
        logger.info "[avatax] response - result=success doc_id=#{response[:doc_id]} doc_code=#{response[:doc_code]} transaction_id=#{response[:transaction_id]}"
        logger.debug { "[avatax] response: #{response.to_json}" }
      else
        logger.error "[avatax] response - result=error doc_id=#{response[:doc_id]} doc_code=#{response[:doc_code]} transaction_id=#{response[:transaction_id]}"
        logger.error "[avatax] response: #{response.to_json}"
        raise FailedApiResponse.new(response)
      end
    end

  end

end
