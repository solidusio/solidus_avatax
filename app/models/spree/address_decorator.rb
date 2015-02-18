Spree::Address.class_eval do
  after_save :avatax_clear_tax

  def avatax_clear_tax
    Spree::Order.incomplete.where(ship_address_id: id).each do |order|
      SpreeAvatax::SalesShared.reset_tax_attributes(order)
    end
  end
end
