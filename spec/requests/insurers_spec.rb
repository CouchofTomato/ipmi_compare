require 'rails_helper'

RSpec.describe "Insurers", type: :request do
  let!(:insurer) { create(:insurer) }
  let(:valid_attributes) { attributes_for(:insurer) }
  let(:invalid_attributes) { { name: "", jurisdiction: "" } }

  describe "GET /index" do
    it "returns http success" do
      get insurers_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get insurer_path(insurer)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get new_insurer_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /edit" do
    it "returns http success" do
      get edit_insurer_path(insurer)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new insurer" do
        expect do
          post insurers_path, params: { insurer: valid_attributes }
        end.to change(Insurer, :count).by(1)
      end

      it "redirects to the created insurer" do
        post insurers_path, params: { insurer: valid_attributes }
        expect(response).to redirect_to(insurer_path(Insurer.last))
      end
    end

    context "with invalid parameters" do
      it "does not create a new insurer" do
        expect do
          post insurers_path, params: { insurer: invalid_attributes }
        end.not_to change(Insurer, :count)
      end

      it "returns an unprocessable entity response" do
        post insurers_path, params: { insurer: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /update" do
    context "with valid parameters" do
      let(:new_attributes) { { name: "Updated Insurer" } }

      it "updates the requested insurer" do
        patch insurer_path(insurer), params: { insurer: new_attributes }
        insurer.reload
        expect(insurer.name).to eq("Updated Insurer")
      end

      it "redirects to the insurer" do
        patch insurer_path(insurer), params: { insurer: new_attributes }
        expect(response).to redirect_to(insurer)
      end
    end

    context "with invalid parameters" do
      it "returns an unprocessable entity response" do
        patch insurer_path(insurer), params: { insurer: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /destroy" do
    it "destroys the requested insurer" do
      expect do
        delete insurer_path(insurer)
      end.to change(Insurer, :count).by(-1)
    end

    it "redirects to the insurers list" do
      delete insurer_path(insurer)
      expect(response).to redirect_to(insurers_path)
    end
  end
end
