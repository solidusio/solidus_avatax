module Spree
  Order.class_eval do

    Spree::Order.state_machine.after_transition :to => :complete, :do => :commit_avatax_invoice

    #TODO-  Avatax Refunds!

    #TODO: Findout what this TODO means
    #TODO: Findout why we do this same logic pretty much twice with calculator/avatax.rb
    def commit_avatax_invoice
      begin
        Avalara.password = SpreeAvatax::Config.password
        Avalara.username = SpreeAvatax::Config.username
        Avalara.endpoint = SpreeAvatax::Config.endpoint

        # Only send the line items that return true for avataxable
        matched_line_items = self.line_items.select do |line_item|
          line_item.avataxable?
        end
            
        invoice_lines =[]
        line_count = 0

        matched_line_items.each do |matched_line_item|
          line_count = line_count + 1
          matched_line_amount = matched_line_item.price * matched_line_item.quantity
          invoice_line = Avalara::Request::Line.new(
            :line_no => line_count.to_s,
            :destination_code => '1',
            :origin_code => '1',
            :qty => matched_line_item.quantity.to_s,
            :amount => matched_line_amount.to_s,
            :item_code => matched_line_item.variant.sku,
            :discounted => self.promotion_adjustment_total != 0 ? true : false
            )
          invoice_lines << invoice_line                
        end

        invoice_addresses = []
        invoice_address = Avalara::Request::Address.new(
          :address_code => '1',
          :line_1 => self.ship_address.address1.to_s,
          :line_2 => self.ship_address.address2.to_s,
          :city => self.ship_address.city.to_s,
          :postal_code => self.ship_address.zipcode.to_s
          )
        invoice_addresses << invoice_address

        invoice = Avalara::Request::Invoice.new(
          :customer_code => self.email,
          :doc_date => Date.today,
          :doc_type => 'SalesInvoice',
          :company_code => SpreeAvatax::Config.company_code,
          :doc_code => self.number,
          :discount => self.promotion_adjustment_total.to_s,
          :commit => 'true'
          )

        invoice.addresses = invoice_addresses
        invoice.lines = invoice_lines
        
        # Log request
        logger.debug 'Avatax Request - '
        logger.debug invoice.to_s

        # Indicate this was avataxed
        update_attribute(:avatax_response_at, Time.now)

        invoice_tax = Avalara.get_tax(invoice)
        
        # Log Response
        logger.debug 'Avatax Response - '
        logger.debug invoice_tax.to_s

      rescue => error
        handle_error(error)
      end
    end

    def handle_error(error) 
      logger.error 'Avatax Commit Failed!'
      logger.error error.to_s
    end

    ##
    # Calculates the total discount of all eligible promotions for Avatax Discount
    # http://developer.avalara.com/api-docs/avalara-avatax-api-reference
    #
    def promotion_adjustment_total 
      return 0 if adjustments.nil?
      total = adjustments.select { |i| i.eligible == true && i.originator_type.constantize == Spree::PromotionAction}.inject(0) { |sum, i| sum + i.amount.to_f }
      total.abs 
    end
  end
end
