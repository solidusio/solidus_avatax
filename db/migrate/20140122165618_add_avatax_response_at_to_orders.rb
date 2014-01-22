class AddAvataxResponseAtToOrders < ActiveRecord::Migration
  def change
    add_column :spree_orders, :avatax_response_at, :datetime
  end
end
