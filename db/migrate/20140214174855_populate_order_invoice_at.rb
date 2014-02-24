class PopulateOrderInvoiceAt < ActiveRecord::Migration
  def up 
    # For legacy orders, assume that if we calculated an Avatax for the order, we also invoiced it.
    Spree::Order.update_all "avatax_invoice_at = avatax_response_at"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
