Spree::PromotionHandler::Coupon.class_eval do
  prepend Module.new do
    def apply
      super.tap do
        if successful?
          SpreeAvatax::SalesShared.reset_tax_attributes(order)
        end
      end
    end
  end
end
