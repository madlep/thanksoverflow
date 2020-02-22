require 'rails_helper'

RSpec.describe V01::AdminController, type: :request do

  describe "POST import_credits" do
    before do
      expect(HTTP).to receive(:get).and_return(
        HTTP::Response.new(
          status: 200,
          version: 1.1,
          body: File.read("spec/fixtures/person_31_combined_credits.json")
        )
      )
    end

    it "runs without error" do
      post v01_admin_import_credits_path()
      expect(flash[:notice]).to match(/Imported \d+ new credits, updated \d+/)
    end
  end
end
