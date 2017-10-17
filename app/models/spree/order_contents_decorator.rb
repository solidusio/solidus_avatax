module SpreeAvatax
  module Extensions
    module OrderContents
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
end

::Spree::OrderContents.prepend SpreeAvatax::Extensions::OrderContents
