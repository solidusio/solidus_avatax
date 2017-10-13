module SpreeAvatax
  module Extensions
    module Order
      def self.prepended(base)
        base.has_one  :avatax_sales_invoice, class_name: 'SpreeAvatax::SalesInvoice', inverse_of: :order

        base.after_save :avatax_order_after_save

        base.state_machine.after_transition from: :address do |order, transition|
          SpreeAvatax::SalesShared.reset_tax_attributes(order)
        end

        base.state_machine.after_transition to: :complete do |order, transition|
          ::CommitSalesInvoiceJob.perform_later(order.id)
        end

        base.state_machine.after_transition to: :canceled do |order, transition|
          SpreeAvatax::SalesInvoice.cancel(order)
        end
      end

      # The total of discounts and charges added at the order level.
      # This intentionally excludes line item & shipment level discounts as those are sent to avatax
      # by being wrapped into net amount of the line item/shipment itself.
      def avatax_order_adjustment_total
        # We invert the sign because avatax calls this the "discount" even though it can handle charges
        # as well as discounts
        -adjustments.non_tax.eligible.sum(:amount)
      end

      def avatax_order_after_save
        # NOTE: DO NOT do anything that will trigger any saves inside of here.  It will cause infinite
        #       recursion since it will cause another "after_save" to be called with the dirty attributes
        #       in the same state. Instead just move the order out of the "confirm" state so that it
        #       will have to go through tax calculations again.
        if ship_address_id_changed? && confirm?
          Rails.logger.info "[avatax] order address change detected for order #{number} while in confirm state. resetting order state to 'payment'."
          update_columns(state: 'payment', updated_at: Time.now)
        end
      end

      def pos_order?
        channel == 'pos'
      end
    end
  end
end

::Spree::Order.prepend ::SpreeAvatax::Extensions::Order
