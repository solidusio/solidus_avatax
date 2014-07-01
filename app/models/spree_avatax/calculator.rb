require_dependency 'spree/calculator'

#
# This is a no-op calculator that just returns the existing value.
# We hook our tax calculations in SpreeAvatax::TaxComputer at the order level instead of here at the line item level
#

class SpreeAvatax::Calculator < Spree::Calculator
  class DoNotUseCompute < StandardError; end
  class TooManyPossibleAdjustments < StandardError; end

  def self.description
    Spree.t(:avatax_description)
  end

  def compute(computable)
    raise DoNotUseCompute.new("The avatax calculator should never use #compute")
  end
end
