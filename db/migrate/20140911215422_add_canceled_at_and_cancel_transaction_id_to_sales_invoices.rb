class AddCanceledAtAndCancelTransactionIdToSalesInvoices < ActiveRecord::Migration
  def change
    add_column :spree_avatax_sales_invoices, :canceled_at, :datetime
    add_column :spree_avatax_sales_invoices, :cancel_transaction_id, :string
  end
end
