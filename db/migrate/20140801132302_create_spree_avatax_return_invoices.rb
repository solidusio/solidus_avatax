class CreateSpreeAvataxReturnInvoices < ActiveRecord::Migration
  def change
    create_table :spree_avatax_return_invoices do |t|
      t.integer :reimbursement_id
      t.boolean :committed
      t.string  :doc_id
      t.string  :doc_code
      t.date    :doc_date
      t.decimal :pre_tax_total, precision: 10, scale: 2
      t.decimal :additional_tax_total, precision: 10, scale: 2

      t.timestamps
    end

    add_index :spree_avatax_return_invoices, :reimbursement_id, unique: true
    add_index :spree_avatax_return_invoices, :doc_id, unique: true
    add_index :spree_avatax_return_invoices, :doc_code, unique: true
  end
end
