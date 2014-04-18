Spree::PromotionHandler::Coupon.class_eval do
  def apply_with_avatax
    apply_without_avatax.tap do
      SpreeAvatax::TaxComputer.new(order).compute if successful?
    end
  end

  alias_method_chain :apply, :avatax
end
