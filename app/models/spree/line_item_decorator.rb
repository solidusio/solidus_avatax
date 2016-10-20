Spree::LineItem.class_eval do

  def self.with_tax_rates
    lis = select { |li| li.taxable? }

    where(id: lis.map(&:id))
  end

  def taxable?
    product.tax_category.tax_rates.any?
  end
end
