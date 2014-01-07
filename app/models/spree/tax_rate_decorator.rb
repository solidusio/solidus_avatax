module Spree
  TaxRate.class_eval do

    private
    
    def create_label
      "Tax"
    end
  end
end
