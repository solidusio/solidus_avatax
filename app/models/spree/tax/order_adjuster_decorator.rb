Spree::Tax::OrderAdjuster.class_eval do
  prepend Module.new do
    def adjust!
      # do nothing. we hook in in our own ways.
      # TODO: See if we can make OrderAdjuster pluggable and workable for what we
      # need to do.
    end
  end
end
