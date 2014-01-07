Spree Avatax
===========

Introduction goes here.

This is an update to the original Spree Avatax gem (https://github.com/markalinn/Spree-Avatax) to work with Spree 2.1.x.

Changes
-------

* Update to use Spree Core 2.1.2 and generated with latest spree extension generator.
* Update to to use latest Avalara gem (0.0.3) as a dependency and remove local Avalara code.
* Update Hashie gem.
* Introduced Honeybadger alerts for when code reverts to standard Spree behavior when Avalara goes down.
* Introduced Pagerduty alerts for when code reverts to standard Spree behavior when Avalara goes down.
* Very rough attempt to start adding test coverage.
* Allow for selective suppression or raising of Avalara errors.

App Configuration
-----------------

Unlike the old gem which used a Rails installation generator, the new Avatax calculator can be integrated via the prescribed Spree 2.1.x method of adding to the calculators array in your configuration file, http://guides.spreecommerce.com/developer/calculators.html.

```
# inside config/initializers/spree.rb
config = Rails.application.config
config.spree.calculators.tax_rates << Spree::Calculator::Avatax
config.spree.calculators.shipping_methods << Spree::Calculator::Avatax
config.spree.calculators.promotion_actions_create_adjustments << Spree::Calculator::Avatax
```

You will also need an avatax.yml file under config with your Avatax account information. A sample is below.

```
default: &default
  username:     'YOUR ID'
  password:     'YOUR LICENSE KEY'
  endpoint:     'https://development.avalara.net/'
  company_code: 'YOUR COMPANY'

development:
  <<: *default

test: 
  <<: *default

staging: 
  <<: *default

integration: 
  <<: *default

production: 
  <<: *default
  endpoint:     'https://avatax.avalara.net/'
```

Admin Configuration
-------------------

Once Avatax is configured, you should be able to select Avatax as a calculator for all tax rules. This can be done in the Spree Admin, http://localhost:3000/admin/tax_rates/ and editing each existing rule.

Testing
-------

The app tries to follow the test setup recommended by Spree Extensions, http://guides.spreecommerce.com/developer/extensions_tutorial.html.

To test, you will need a test application, then you can run the tests.

```
bundle exec rake test_app
```

Create a configuration file under spec/dummy/config/avatax.yml that looks like the following:

```
default: &default
  username:       'Your ID'
  password:       'Your License'
  endpoint:       'https://development.avalara.net/'
  company_code:   'Your Company'

test:
  <<: *default
```

Run tests!

```
bundle exec rake spec
```

TODO
----

* Understand the impact of this TODO from the original author, https://github.com/HoyaBoya/Spree-Avatax/blob/master/app/models/spree/calculator/avatax.rb#L99

Installation
------------

Add spree_avatax to your Gemfile:

```ruby
gem 'spree_avatax'
```

Bundle your dependencies and run the installation generator:

```shell
bundle
bundle exec rails g spree_avatax:install
```

Copyright (c) 2014 [HoyaBoya], released under the New BSD License
