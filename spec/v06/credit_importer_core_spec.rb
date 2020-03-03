require 'rails_helper'

module V06
  include Result
  include Option

  RSpec.describe CreditImporterCore do
    subject{CreditImporterCore}
    let(:import_summary) { ImportSummary.new(0,0,0)}

    let(:insert_title) {
      f = double("insert_title")
      allow(f).to receive(:call){|insert_attrs|
        if Title.new(**insert_attrs).valid?
          Success.new("inserted title")
        else
          Failure.new("invalid title")
        end
      }
      f
    }

    describe "when fetch_credits succeeds, and JSON parsing succeeds" do
      let(:fetch_credits) {
        -> () {
          credits = File.read("spec/fixtures/person_31_combined_credits.json")
          Success.new(credits)
        }
      }

      describe "and find_title does not find anything" do
        let(:find_title) {
          ->(_tmdb_id){Option.of(nil)}
        }


        let(:update_title) {
          ->(**_update_attrs){ raise "shouldn't be called"}
        }

        it "inserts all the titles" do
          expect(insert_title).to receive(:call).exactly(163).times
          success = subject.(fetch_credits, find_title, insert_title, update_title, import_summary)
          expect(success.success?).to eq(true)

          result = success.result

          expect(result.inserted_count).to eq(104)
          expect(result.updated_count).to eq(0)
          expect(result.error_count).to eq(59)
        end
      end

      describe "and find_title finds some of the titles" do
        let!(:forest_gump_tmdb_id) { 13 }

        let(:find_title) {
          ->(tmdb_id){
            if tmdb_id == forest_gump_tmdb_id
              Some.new("forest gump")
            else
              None.new
            end
          } 
        }

        let(:update_title) {
          f = double("update_title")
          allow(f).to receive(:call){|title, update_attrs| Success.new("updated title")}
          f
        }

        it "inserts and updates the titles" do
          expect(insert_title).to receive(:call).exactly(162).times
          expect(update_title).to receive(:call).exactly(1).time.with("forest gump", Hash)
          success = subject.(fetch_credits, find_title, insert_title, update_title, import_summary)
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

      let(:find_title) { ->(_tmdb_id){raise "should not be called"} }

      let(:insert_title) { ->(insert_attrs) { raise "should not be called" } }

      let(:update_title) { ->(title, update_attrs) { raise "should not be called" } }

      it "returns a failure value" do
        failure = subject.(fetch_credits, find_title, insert_title, update_title, import_summary)
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

      let(:find_title) { ->(_tmdb_id){raise "should not be called"} }

      let(:insert_title) { ->(insert_attrs) { raise "should not be called" } }

      let(:update_title) { ->(title, update_attrs) { raise "should not be called" } }

      it "returns a failure value" do
        failure = subject.(fetch_credits, find_title, insert_title, update_title, import_summary)
        expect(failure.failure?).to eq(true)
        expect(failure.message).to be_instance_of(JSON::ParserError)
      end
    end
  end
end