require 'rails_helper'

RSpec.describe V03::AdminController, type: :request do

  describe "POST import_credits" do
    describe "when http call works, and JSON parsing works" do
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
        post v03_admin_import_credits_path()
        expect(flash[:notice]).to match(/Imported \d+ new credits, updated \d+/)
      end
    end

    describe "when http call fails with non-200 return" do
      before do
        expect(HTTP).to receive(:get).and_return(
          HTTP::Response.new(
            status: 500,
            version: 1.1,
            body: "something broke"
          )
        )
      end

      it "will error due to bad JSON" do
        post v03_admin_import_credits_path()
        expect(flash[:notice]).to be_nil
        expect(flash[:error]).to eq("error fetching credits. Status=500 Internal Server Error")
      end
    end

    describe "when JSON parsing fails due to bad data" do
      before do
        expect(JSON).to receive(:parse).and_raise(JSON::ParserError)
      end

      it "will bubble up the error" do
        post v03_admin_import_credits_path()
        expect(flash[:notice]).to be_nil
        expect(flash[:error]).to be_instance_of(JSON::ParserError)
      end
    end
  end
end
