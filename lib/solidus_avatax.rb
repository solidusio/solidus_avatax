require 'spree_core'
require 'spree_avatax/engine'
require 'avatax_taxservice'

module SpreeAvatax
  class AvataxTimeout < Timeout::Error; end
end
