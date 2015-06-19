require "spec_helper"

RSpec.describe "Taxes with Store Credits" do
  let(:user) { FactoryGirl.create(:user, password: "Alderaan") }

  before do
    # Set up Avatax (just in case we don't have a cassette)
    config = YAML.load_file("spec/avalara_config.yml")
    SpreeAvatax::Config.password = config['password']
    SpreeAvatax::Config.username = config['username']
    SpreeAvatax::Config.service_url = config['service_url']
    SpreeAvatax::Config.company_code = 'Bonobos'

    # Set up a zone
    zone = FactoryGirl.create(:zone)
    country = FactoryGirl.create(:country, name: "Tatooine")
    zone.members << Spree::ZoneMember.create(zoneable: country)

    # Product, payment method and shipping method
    FactoryGirl.create(:credit_card_payment_method)
    FactoryGirl.create(:store_credit_payment_method)
    FactoryGirl.create(:free_shipping_method)
    FactoryGirl.create(:product, name: "DL-44", price: 19.99)

    # Login
    visit spree.login_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "Alderaan"
    click_button "Login"

    # Add product to our cart
    visit spree.root_path
    click_link "DL-44"
    click_button "Add To Cart"
  end

  context "when there are enough credits to cover everything" do
    before do
      # Add enough credit to cover the order.
      FactoryGirl.create(
        :store_credit, user: user, amount: 1000.00
      )

      click_button "Checkout"

      # Address
      within("#billing") do
        fill_in "First Name", with: "Han"
        fill_in "Last Name", with: "Solo"
        fill_in "Street Address", with: "YT-1300"
        fill_in "City", with: "Mos Eisley"
        select "United States of America", from: "Country"
        fill_in "order_bill_address_attributes_state_name", with: "Tatooine"
        fill_in "Zip", with: "12010"
        fill_in "Phone", with: "(555) 555-5555"
      end
      click_on "Save and Continue"

      # Delivery
      click_on "Save and Continue"
    end

    it "adjusts the credits to cover taxes" do
      # Enter credit card details. Won't let us continue without it.
      fill_in "Name on card", with: "Han Solo"
      fill_in "Card Number", with: "4111111111111111"
      fill_in "card_expiry", with: "04 / 20"
      fill_in "Card Code", with: "123"

      # Use a cassette so that we don't hit the Avatax API all of the time.
      VCR.use_cassette("taxes_with_store_credits") do
        click_button "Save and Continue"
      end

      # Should have $1.60 in tax.
      within("#tax-adjustments") do
        expect(page).to have_content("$1.60")
      end

      # Store credit should cover everything.
      # Product + Tax   = Total
      # $19.99  + $1.60 = $21.59
      within("#store-credit") do
        expect(page).to have_content("-$21.59")
      end

      # Order total should be $0.00
      within("#order-total") do
        expect(page).to have_content("$0.00")
      end
    end
  end
end
