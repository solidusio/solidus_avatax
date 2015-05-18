class FixAvataxShortShipIndex < ActiveRecord::Migration
  def up
    remove_index(
      :spree_avatax_short_ship_return_invoice_inventory_units,
      name: 'index_spree_avatax_short_ships_on_invoice_id',
    )

    # Was previously set as unique, which was not correct -- A short ship return
    # invoice may have multiple units associated with it
    add_index(
      :spree_avatax_short_ship_return_invoice_inventory_units,
      :short_ship_return_invoice_id,
      name: 'index_spree_avatax_short_ships_on_invoice_id',
    )
  end

  def down
    remove_index(
      :spree_avatax_short_ship_return_invoice_inventory_units,
      name: 'index_spree_avatax_short_ships_on_invoice_id',
    )

    add_index(
      :spree_avatax_short_ship_return_invoice_inventory_units,
      :short_ship_return_invoice_id,
      unique: true,
      name: 'index_spree_avatax_short_ships_on_invoice_id',
    )
  end
end
