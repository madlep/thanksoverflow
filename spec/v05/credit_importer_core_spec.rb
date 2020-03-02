require 'rails_helper'

module V05
  include Result

  RSpec.describe CreditImporterCore do
    subject{CreditImporterCore}
    let(:import_summary) { ImportSummary.new(0,0,0)}

    describe "when fetch_credits succeeds, and JSON parsing succeeds" do
      let(:fetch_credits) {
        -> () {
          credits = File.read("spec/fixtures/person_31_combined_credits.json")
          Success.new(credits)
        }
      }

      describe "and find_title does not find anything" do
        let(:find_title) {
          ->(_tmdb_id){nil}
        }

        it "inserts all the titles" do
          expect(Title.count).to eq(0)
          success = subject.(fetch_credits, find_title, import_summary)
          expect(Title.count).to eq(104)

          expect(success.success?).to eq(true)

          result = success.result

          expect(result.inserted_count).to eq(104)
          expect(result.updated_count).to eq(0)
          expect(result.error_count).to eq(59)
        end
      end

      describe "and find_title finds some of the titles" do
        let!(:forest_gump) {
          title = Title.create!(
            tmdb_id: 13,
            title: "Forrest Gump",
            character: "Forrest Gump",
            release_date: "1994-07-06",
            media_type: "movie",
            popularity: 0.31462e2,
            synced_at: "2020-02-22 03:48:06"
          )
          title
        }

        let(:find_title) {
          ->(tmdb_id){
            if tmdb_id == forest_gump.tmdb_id
              forest_gump
            else
              nil
            end
          } 
        }

        it "inserts and updates the titles" do
          expect(Title.count).to eq(1)
          success = subject.(fetch_credits, find_title, import_summary)
          expect(Title.count).to eq(104)

          expect(success.success?).to eq(true)

          result = success.result

          expect(result.inserted_count).to eq(103)
          expect(result.updated_count).to eq(1)
          expect(result.error_count).to eq(59)
        end
      end
    end

    describe "when fetch_credits fails" do
      let(:fetch_credits) {
        -> () {
          Failure.new(HTTP::Error.new("something went bad"))
        }
      }

        let(:find_title) {
          ->(_tmdb_id){raise "should not be called"}
        }

      it "returns a failure value" do
        failure = subject.(fetch_credits, find_title, import_summary)
        expect(failure.failure?).to eq(true)
        expect(failure.message).to be_instance_of(HTTP::Error)
      end
    end

    describe "when JSON parsing fails" do
      let(:fetch_credits) {
        -> () {
          Success.new("bad json")
        }
      }

      let(:find_title) {
        ->(_tmdb_id){raise "should not be called"}
      }

      it "returns a failure value" do
        failure = subject.(fetch_credits, find_title, import_summary)
        expect(failure.failure?).to eq(true)
        expect(failure.message).to be_instance_of(JSON::ParserError)
      end
    end
  end
end