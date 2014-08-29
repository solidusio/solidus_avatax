Spree::PromotionHandler::Coupon.class_eval do
  def apply_with_avatax
    apply_without_avatax.tap do
      if successful?
        SpreeAvatax::SalesOrder.generate(order)
      end
    end
  end

  alias_method_chain :apply, :avatax
end
