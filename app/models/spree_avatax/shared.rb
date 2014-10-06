module SpreeAvatax::Shared
  class FailedApiResponse < StandardError
    attr_reader :response, :messages

    def initialize(response)
      @response = response
      @messages = Array.wrap(response[:messages][:message])
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
        use_production_account: SpreeAvatax::Config.use_production_account,
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