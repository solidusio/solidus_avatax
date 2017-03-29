module Solidus
  module Avatax
    module PromotionHandler
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

Spree::PromotionHandler::Coupon.send(:prepend, Solidus::Avatax::PromotionHandler)
