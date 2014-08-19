module SpreeAvatax
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace SpreeAvatax
    engine_name 'spree_avatax'

    initializer 'spree_avatax.register.calculators', after: 'spree.register.calculators' do |app|
      app.config.spree.calculators.tax_rates << SpreeAvatax::Calculator
      app.config.spree.calculators.shipping_methods << SpreeAvatax::Calculator
    end

    initializer 'spree_avatax.promo.register.promotion.calculators', after: 'spree.promo.register.promotion.calculators' do |app|
      app.config.spree.calculators.promotion_actions_create_adjustments << SpreeAvatax::Calculator
    end

    config.autoload_paths += %W(#{config.root}/lib)

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    config.to_prepare &method(:activate).to_proc
  end
end
