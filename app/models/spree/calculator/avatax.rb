require_dependency 'spree/calculator'

#
# This is a no-op calculator that just returns the existing value.
# We hook our tax calculations in SpreeAvatax::TaxComputer at the order level instead of here at the line item level
#

module Spree
  class Calculator::Avatax < Calculator
    class TooManyPossibleAdjustments < StandardError; end

    def self.description
      Spree.t(:avatax_description)
    end

    ##
    # We need to return the original adjustment amount of tax amount.
    # This is invoked:
    # https://github.com/spree/spree/blob/bd437de/core/app/models/spree/adjustment.rb#L76-L89
    # Via:
    # https://github.com/spree/spree/blob/bd437de/core/app/models/spree/item_adjustments.rb#L41-L42
    #
    # We are supporting this as a calculator so that a Spree TaxRate can be created with this calculator to complete the object graph.
    # If we return 0 or anything else, we will be clobbering the taxes we just calculated from Avatax :/
    #
    def compute_line_item(line_item)
      return 0 if line_item.adjustments.eligible.tax.additional.empty?
      raise TooManyPossibleAdjustments if line_item.adjustments.eligible.tax.additional.size > 1
      line_item.adjustments.eligible.tax.additional.first.amount
    end

    def compute_shipping_rate(shipping_rate)
      return 0 if shipping_rate.cost == 0
      raise NotImplementedError
    end

    def compute_shipment(shipping_rate)
      raise NotImplementedError
    end
  end
end
