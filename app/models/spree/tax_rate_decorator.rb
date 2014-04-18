Spree::TaxRate.class_eval do
  validate :avatax_there_can_be_only_one, on: :create

  # require exactly one tax rate.  if that's not true then alert ourselves and carry on as best we can
  def self.avatax_the_one_rate
    rates = all.to_a
    if rates.size != 1
      if defined?(Honeybadger)
        Honeybadger.notify("#{rates.size} tax rates detected and there should be only one")
      end
    end
    rates.sort_by(&:id).first
  end

  def avatax_there_can_be_only_one
    if Spree::TaxRate.count > 0
      errors.add(:base, "only one tax rate is allowed and this would make #{Spree::TaxRate.count+1}")
    end
  end
end
