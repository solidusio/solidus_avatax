module SpreeAvatax
  module Extensions
    module Tax
      module OrderAdjuster
        def adjust!
          super if rates_for_order_zone(order).avatax.none?
        end
      end
    end
  end
end

::Spree::Tax::OrderAdjuster.prepend \
  SpreeAvatax::Extensions::Tax::OrderAdjuster
