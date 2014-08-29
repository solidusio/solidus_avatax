class CreateSpreeAvataxSalesOrders < ActiveRecord::Migration
  def change
    create_table :spree_avatax_sales_orders do |t|
      t.integer :order_id,             null: false
      t.string  :doc_code,             null: false
      t.date    :doc_date,             null: false
      t.decimal :pre_tax_total,        precision: 10, scale: 2
      t.decimal :additional_tax_total, precision: 10, scale: 2

      t.timestamps
    end

    add_index :spree_avatax_sales_orders, :order_id
  end
end
