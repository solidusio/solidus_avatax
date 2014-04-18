Spree::Address.class_eval do
  after_save :avatax_compute_tax

  def avatax_compute_tax
    if order = Spree::Order.where(:ship_address_id => id).first
      SpreeAvatax::TaxComputer.new(order).compute
    end
  end
end
