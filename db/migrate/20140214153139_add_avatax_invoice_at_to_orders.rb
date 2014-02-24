class AddAvataxInvoiceAtToOrders < ActiveRecord::Migration
  def change 
    add_column :spree_orders, :avatax_invoice_at, :datetime
  end
end
