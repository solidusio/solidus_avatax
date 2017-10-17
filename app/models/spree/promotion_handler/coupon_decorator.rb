module SpreeAvatax
  module Extensions
    module PromotionHandler
      module Coupon
        def apply
          super.tap do
            if successful?
              SpreeAvatax::SalesShared.reset_tax_attributes(order)
            end
          end
        end
      end
    end
  end
end

::Spree::PromotionHandler::Coupon.prepend \
  SpreeAvatax::Extensions::PromotionHandler::Coupon
