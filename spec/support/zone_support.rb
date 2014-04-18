module ZoneSupport
  def self.global_zone
    # seem to be netting zones in the db somehow and there is a uniqueness constraint
    Spree::Zone.find_by_name("GlobalZone") || FactoryGirl.create(:global_zone)
  end
end
