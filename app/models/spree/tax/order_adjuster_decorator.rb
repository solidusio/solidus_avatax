Spree::Tax::OrderAdjuster.class_eval do
  def adjust_with_avatax!
    # do nothing. we hook in in our own ways.
    # TODO: See if we can make OrderAdjuster pluggable and workable for what we
    # need to do.
  end

  alias_method_chain :adjust!, :avatax
end
