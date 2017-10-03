module SpreeAvatax
  module Extensions
    module Adjustment
      def self.prepended(base)
        # We always want tax adjustments to be "closed" because that tells Spree not to try to recalculate them automatically.
        base.validates(
          :finalized,
          {
            inclusion: {
              in: [true],
              message: "Tax adjustments must always be finalized for Avatax",
            },
            if: :avatax?
          }
        )

        if !defined?(base.non_tax) # Spree 2.4+ has this scope already
          base.scope :non_tax, -> do
            source_type = arel_table[:source_type]
            where(source_type.not_eq('Spree::TaxRate').or source_type.eq(nil))
          end
        end
      end

      private

      def avatax?
        tax? && self.source.avatax?
      end
    end
  end
end

::Spree::Adjustment.prepend \
  SpreeAvatax::Extensions::Adjustment
