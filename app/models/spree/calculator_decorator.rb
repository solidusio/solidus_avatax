module SpreeAvatax
  module Extensions
    module Calculator
      def avatax?
        false
      end
    end
  end
end

::Spree::Calculator.prepend ::SpreeAvatax::Extensions::Calculator
