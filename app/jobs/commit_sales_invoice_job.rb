class CommitSalesInvoiceJob < ActiveJob::Base
  queue_as :default

  def perform(order_id)
    order = ::Spree::Order.find(order_id)
    return if order.pos_order?
    SpreeAvatax::SalesInvoice.commit(order)
  end
end
