require 'rails_helper'

module V05
  RSpec.describe AdminController, type: :request do

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

          Title.create!(
            tmdb_id: 13,
            title: "Forrest Gump",
            character: "Forrest Gump",
            release_date: "1994-07-06",
            media_type: "movie",
            popularity: 0.31462e2,
            synced_at: "2020-02-22 03:48:06"
          )
        end

        it "runs without error" do
          post v05_admin_import_credits_path()
          expect(flash[:notice]).to match(/Imported 103 new credits, updated 1/)
          expect(flash[:error]).to match(/59 titles had errors preventing saving/)
        end
      end

      describe "when http call fails due to error" do
        before do
          expect(HTTP).to receive(:get).and_raise(HTTP::Error.new("something broke"))
        end

        it "will return the failure" do
          post v05_admin_import_credits_path()
          expect(flash[:notice]).to be_nil
          expect(flash[:error]).to eq("Fatal error prevented import: #<HTTP::Error: something broke>")
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
          post v05_admin_import_credits_path()
          expect(flash[:notice]).to be_nil
          expect(flash[:error]).to eq("Fatal error prevented import: \"error fetching credits. Status=500 Internal Server Error\"")
        end
      end

      describe "when JSON parsing fails due to bad data" do
        before do
          expect(JSON).to receive(:parse).and_raise(JSON::ParserError.new("foo was too bar"))
        end

        it "will bubble up the error" do
          post v05_admin_import_credits_path()
          expect(flash[:notice]).to be_nil
          expect(flash[:error]).to eq("Fatal error prevented import: #<JSON::ParserError: foo was too bar>")
        end
      end
    end
  end
end