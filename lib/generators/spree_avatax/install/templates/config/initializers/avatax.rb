# Avatax Setup
SpreeAvatax::Config.username = 'your avatax username'
SpreeAvatax::Config.password = 'your avatax password'
SpreeAvatax::Config.company_code = 'your avatax company code'
SpreeAvatax::Config.use_production_account = Rails.env.production?
# The "endpoint" config will soon be replaced by the "use_production_account" config
SpreeAvatax::Config.endpoint = Rails.env.production? ? 'https://avatax.avalara.net/': 'https://development.avalara.net/'
