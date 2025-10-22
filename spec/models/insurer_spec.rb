require 'rails_helper'

RSpec.describe Insurer, type: :model do
  subject(:insurer) { create(:insurer) }

  it { expect(insurer).to have_one_attached(:logo) }
  it { expect(insurer).to have_many(:plans).dependent(:destroy) }
  it { expect(insurer).to validate_presence_of :name }
  it { expect(insurer).to validate_presence_of :jurisdiction }

  describe "#country_name" do
    it "returns the translated country name for the current locale when available" do
      country = instance_double(
        ISO3166::Country,
        translations: { "es" => "Estados Unidos" },
        common_name: "United States of America",
        iso_short_name: "United States of America"
      )
      allow(ISO3166::Country).to receive(:[]).with("US").and_return(country)

      result = I18n.with_locale(:es) do
        build(:insurer, jurisdiction: "US").country_name
      end

      expect(result).to eq("Estados Unidos")
    end

    it "falls back to the common name when no translation exists for the locale" do
      country = instance_double(
        ISO3166::Country,
        translations: {},
        common_name: "United States Minor Outlying Islands",
        iso_short_name: "United States Minor Outlying Islands"
      )
      allow(ISO3166::Country).to receive(:[]).with("UM").and_return(country)

      expect(build(:insurer, jurisdiction: "UM").country_name)
        .to eq("United States Minor Outlying Islands")
    end

    it "falls back to the ISO short name when translation and common name are missing" do
      country = instance_double(
        ISO3166::Country,
        translations: {},
        common_name: nil,
        iso_short_name: "Cocos (Keeling) Islands"
      )
      allow(ISO3166::Country).to receive(:[]).with("CC").and_return(country)

      expect(build(:insurer, jurisdiction: "CC").country_name)
        .to eq("Cocos (Keeling) Islands")
    end
  end
end
