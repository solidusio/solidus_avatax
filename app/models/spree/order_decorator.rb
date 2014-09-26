Spree::Order.class_eval do

  has_one  :avatax_sales_invoice, class_name: 'SpreeAvatax::SalesInvoice', inverse_of: :order
  has_many :avatax_sales_orders,  class_name: 'SpreeAvatax::SalesOrder', inverse_of: :order

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

end
