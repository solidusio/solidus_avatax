module Spree
  LineItem.class_eval do
    def avataxable?
      response = false
      #TODO- Need to update this to look at the tax_category
      #and make sure it has a rate that uses Avatax
      rates = product.tax_category.tax_rates
      rates.each do |rate|
        if rate.zone.include?(order.ship_address || order.bill_address)
          response = true
          break
        end
      end
      return response
    end
  end
end
