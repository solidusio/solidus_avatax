module PromotionSupport
  class << self
    def line_item_promotion(order)
      promo = FactoryGirl.create(:promotion_with_item_adjustment, code: 'line_item_promotion')
      promo.rules << Spree::Promotion::Rules::Product.create!(preferred_match_policy: 'any', product_ids_string: order.line_items.first.product.id.to_s)
      promo
    end

    def set_line_item_promotion(order)
      order.coupon_code = line_item_promotion(order).code
      Spree::PromotionHandler::Coupon.new(order).apply
      order.reload
    end

    def order_promotion(order)
      promo = FactoryGirl.create(:promotion, code: "order_promotion")
      calculator = Spree::Calculator::FlatRate.new
      calculator.preferred_amount = 10
      Spree::Promotion::Actions::CreateAdjustment.create!(calculator: calculator, promotion: promo)
      promo
    end

    def set_order_promotion(order)
      order.coupon_code = order_promotion(order).code
      Spree::PromotionHandler::Coupon.new(order).apply
      order.reload
    end
  end
end
