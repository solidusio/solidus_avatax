Spree::Order.class_eval do

  has_one  :avatax_sales_invoice, class_name: 'SpreeAvatax::SalesInvoice', inverse_of: :order
  has_many :avatax_sales_orders,  class_name: 'SpreeAvatax::SalesOrder', inverse_of: :order

  after_save :avatax_order_after_save

  state_machine.after_transition from: :address do |order, transition|
    SpreeAvatax::SalesOrder.generate(order)
  end

  state_machine.before_transition to: :confirm do |order, transition|
    SpreeAvatax::SalesInvoice.generate(order)
  end

  state_machine.after_transition to: :complete do |order, transition|
    SpreeAvatax::SalesInvoice.commit(order)
  end

  state_machine.after_transition to: :canceled do |order, transition|
    SpreeAvatax::SalesInvoice.cancel(order)
  end

  def avatax_promotion_adjustment_total
    adjustments.promotion.eligible.sum(:amount).abs
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

end
