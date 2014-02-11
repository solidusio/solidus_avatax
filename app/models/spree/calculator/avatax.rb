require_dependency 'spree/calculator'

module Spree
  class Calculator < ActiveRecord::Base
    class Avatax < Calculator
      attr_accessor :pager_duty_client

      include Spree::Calculator::DefaultTaxMethods

      def self.description
        I18n.t(:avalara_tax)
      end

      def avatax_logger
        @@avatax_logger ||= Logger.new("#{Rails.root}/log/avatax.log")
      end

      def compute(computable)
        case computable
          when Spree::Order
            avatax_compute_order(computable)
          when Spree::LineItem
            avatax_compute_line_item(computable)
        end
      end
  
      private
  
      def rate
        self.calculable
      end

      def avatax_compute_order(order)
        # Use Avatax lookup and if fails fall back to default Spree taxation rules
        begin
          Avalara.password = SpreeAvatax::Config.password
          Avalara.username = SpreeAvatax::Config.username
          Avalara.endpoint = SpreeAvatax::Config.endpoint
          
          matched_line_items = order.line_items.select do |line_item|
            line_item.product.tax_category == rate.tax_category
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
              :discounted => order.promotion_adjustment_total != 0 ? true : false
            )
            invoice_lines << invoice_line                
          end

          invoice_addresses = []
          invoice_address = Avalara::Request::Address.new(
            :address_code => '1',
            :line_1 => order.ship_address.address1.to_s,
            :line_2 => order.ship_address.address2.to_s,
            :city => order.ship_address.city.to_s,
            :postal_code => order.ship_address.zipcode.to_s
          )
          invoice_addresses << invoice_address

          # Log Order State
          avatax_logger.debug order.state
          
          invoice = Avalara::Request::Invoice.new(
            :customer_code => order.email,
            :doc_date => Date.today,
            :doc_type => 'SalesOrder',
            :company_code => SpreeAvatax::Config.company_code,
            :discount => order.promotion_adjustment_total.to_s,
            :doc_code => order.number
          )

          invoice.addresses = invoice_addresses
          invoice.lines = invoice_lines
          
          # Log request
          avatax_logger.debug invoice.to_s
          invoice_tax = Avalara.get_tax(invoice)
         
          # Indicate this order was Avatax calculated 
          order.update_attribute(:avatax_response_at, Time.now)

          # Log response
          avatax_logger.debug invoice_tax.to_s
          invoice_tax.total_tax

        rescue => e
          avatax_logger.error(e)
          notify(e, order)

          order.update_attribute(:avatax_response_at, nil)
          compute_order(order)
        end
      end
  
      def avatax_compute_line_item(line_item)
        compute_line_item(line_item)
      end

      ##
      # Notify a Honeybadger that Avalara is down.... :(
      #
      def notify(e, order)
        # Allow certain errors to be not be raised to the alert framework
        # https://github.com/adamfortuna/avalara/blob/master/lib/avalara.rb#L96-L102
        return if e.instance_of?(Avalara::ApiError) && SpreeAvatax::Config.suppress_api_errors?

        alert_params = {
          :error_class   => "Avalara Error: #{e.class}",
          :error_message => "Avalara Error: #{e.message}",
          :parameters    => {order: order.attributes}
        }

        # Notify Honeybadger if the class exists.
        # We assume that it's been configured properly.
        if defined?(Honeybadger)
          Honeybadger.notify(alert_params)
        end

        # Notify Pagerduty if class exists and the client exists
        # We inject the client because we don't want to have the access key passed in and let someone else configure it properly.
        if defined?(Pagerduty) && pager_duty_client
          pager_duty_client.trigger "Avalara Error #{e.class}", alert_params
        end
      end
    end
  end
end
