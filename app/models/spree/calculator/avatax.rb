require_dependency 'spree/calculator'

module Spree
  class Calculator < ActiveRecord::Base
    class Avatax < Calculator
      attr_accessor :pager_duty_client

      include Spree::Calculator::DefaultTaxMethods
      
      def self.description
        I18n.t(:avalara_tax)
      end

      def compute(computable)
        case computable
          when Spree::Order
            avatax_compute_order(computable)
          when Spree::LineItem
            avatax_compute_line_item(computable)
        end
      end

      def doc_type
        'SalesOrder'
      end

      def status_field
        :avatax_response_at
      end

      def build_line_items(order)
        order.line_items.select do |line_item|
          line_item.product.tax_category == rate.tax_category
        end
      end
  
      private
  
      def rate
        self.calculable
      end

      def avatax_compute_order(order)
        SpreeAvatax::AvataxComputer.new.compute_order_with_context(order, self)
      end
  
      def avatax_compute_line_item(line_item)
        compute_line_item(line_item)
      end
    end
  end
end
