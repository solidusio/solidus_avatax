Spree::Adjustment.class_eval do
  # We always want tax adjustments to be "closed" because that tells Spree not to try to recalculate them automatically.
  validates(
    :state,
    {
      inclusion: {
        in: ['closed'],
        message: "Tax adjustments must always be closed for Avatax",
      },
      if: 'source == "Spree::TaxRate"',
    }
  )
end
