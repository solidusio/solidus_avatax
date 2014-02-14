class PopulateOrderInvoiceAt < ActiveRecord::Migration
  def up 
    # For legacy orders, assume that if we calculated an Avatax for the order, we also invoiced it.
    Spree::Order.all.each do |order|
      if order.avatax_response_at
        order.update_attribute(:avatax_invoice_at, order.avatax_response_at)
      end
    end
  end

  def down
    # For legacy orders, assume that if we calculated an Avatax for the order, we also invoiced it.
    Spree::Order.all.each do |order|
      if order.avatax_response_at
        order.update_attribute(:avatax_invoice_at, nil)
      end
    end
  end
end
