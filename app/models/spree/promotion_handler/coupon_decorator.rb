Spree::PromotionHandler::Coupon.class_eval do
  def apply_with_avatax
    apply_without_avatax.tap do
      if successful?
        SpreeAvatax::SalesShared.reset_tax_attributes(order)
      end
    end
  end

  alias_method_chain :apply, :avatax
end
