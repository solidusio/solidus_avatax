Spree::OrderContents.class_eval do
  prepend Module.new do
    def add(*args)
      super.tap do
        SpreeAvatax::SalesShared.reset_tax_attributes(order)
      end
    end

    def remove(*args)
      super.tap do
        SpreeAvatax::SalesShared.reset_tax_attributes(order)
      end
    end


    def update_cart(params)
      if super
        SpreeAvatax::SalesShared.reset_tax_attributes(order)
        true
      else
        false
      end
    end
  end
end
