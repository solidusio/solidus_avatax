module Solidus::Avatax::OrderAdjuster
  def adjust!
    # do nothing. we hook in in our own ways.
    # TODO: See if we can make OrderAdjuster pluggable and workable for what we
    # need to do.
  end
end

Spree::Tax::OrderAdjuster.send(:prepend, Solidus::Avatax::OrderAdjuster)
