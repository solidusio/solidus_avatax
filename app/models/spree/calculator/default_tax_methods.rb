# This code is taken from Spree core. 
# Tried to inherit from Calculator::DefaultTax to have DRY-ness but it was not working.
# This is at least isolated, and not a pure copy/paste job as it was in the original gem.
# https://github.com/spree/spree/blob/master/core/app/models/spree/calculator/default_tax.rb
module Spree
  class Calculator < ActiveRecord::Base
    module DefaultTaxMethods
      def compute_order(order)
        matched_line_items = order.line_items.select do |line_item|
          line_item.tax_category == rate.tax_category
        end

        line_items_total = matched_line_items.sum(&:total)
        round_to_two_places(line_items_total * rate.amount)
      end

      def compute_line_item(line_item)
        if line_item.tax_category == rate.tax_category
          if rate.included_in_price
            deduced_total_by_rate(line_item, rate)
          else
            round_to_two_places(line_item.discounted_amount * rate.amount)
          end
        else
          0
        end
      end

      def round_to_two_places(amount)
        BigDecimal.new(amount.to_s).round(2, BigDecimal::ROUND_HALF_UP)
      end

      def deduced_total_by_rate(line_item, rate)
        combined_taxes = 0
        line_item.product.tax_category.tax_rates.each do |tax|
          combined_taxes += tax.amount
        end
        price_without_taxes = line_item.discounted_amount / (1 + combined_taxes)
        round_to_two_places(price_without_taxes * rate.amount)
      end
    end
  end
end
