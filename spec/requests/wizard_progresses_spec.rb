require 'rails_helper'

RSpec.describe "WizardProgresses", type: :request do
  describe "GET /show" do
    it "returns http success" do
      get "/wizard_progresses/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/wizard_progresses/update"
      expect(response).to have_http_status(:success)
    end
  end

end
