class SpreeAvatax::TaxRateInvalidOperation < StandardError; end

module SpreeAvatax
  module Extensions
    module TaxRate
      module ClassMethods
        def avatax
          all.
            joins(:calculator).
            where("spree_calculators.type = ?", 'SpreeAvatax::Calculator')
        end

        def match(order)
          [avatax_the_one_rate]
        end

        def adjust(order, items)
          return if avatax?

          super
          # do nothing.  we'll take care of this ourselves at different points via the various hooks we have in place
        end

        # require exactly one tax rate.  if that's not true then alert ourselves and carry on as best we can
        def avatax_the_one_rate
          rates = all.to_a
          rates.sort_by(&:id).first
        end
      end

      def self.prepended(base)
        base.validate :avatax_there_can_be_only_one, on: :create
        base.delegate :avatax?, to: :calculator

        class << base
          prepend ClassMethods
        end
      end

      def adjust(order, item)
        if self.avatax?
          # We've overridden the class-level TaxRate.adjust so nothing should be calling this code
          raise SpreeAvatax::TaxRateInvalidOperation.new("Spree::TaxRate#adjust should never be called when Avatax is present")
        else
          super
        end
      end

      private

      def avatax_there_can_be_only_one
        if self.class.avatax.any? && self.avatax?
          errors.add(:base, "only one tax rate is allowed and this would make #{Spree::TaxRate.count+1}")
        end
      end
    end
  end
end

::Spree::TaxRate.prepend \
  SpreeAvatax::Extensions::TaxRate
