Spree::Order.class_eval do

  has_one  :avatax_sales_invoice, class_name: 'SpreeAvatax::SalesInvoice', inverse_of: :order
  has_many :avatax_sales_orders,  class_name: 'SpreeAvatax::SalesOrder', inverse_of: :order

  after_save :avatax_order_after_save
  after_commit :avatax_order_after_commit

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

  def promotion_adjustment_total
    adjustments.promotion.eligible.sum(:amount).abs
  end

  def avatax_order_after_save
    # NOTE: DO NOT do anything that will trigger any saves inside of here.  It will cause infinite
    #       recursion since it will cause another "after_save" to be called with the dirty attributes
    #       in the same state. Instead just flag taxes as needing to be recalculated and then do it
    #       in the avatax_order_after_commit method.  This will again trigger an after_save but this
    #       time the "_changed?" attributes will be reset.
    if ship_address_id_changed? && confirm?
      @recalculate_taxes = true
    end
  end

  def avatax_order_after_commit
    # See above note in avatax_order_after_save
    if @recalculate_taxes
      @recalculate_taxes = nil
      SpreeAvatax::SalesInvoice.generate(self)
    end
  end
end
