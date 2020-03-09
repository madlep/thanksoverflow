require 'rails_helper'

module V07
  include Result
  include Option
  include Actions

  RSpec.describe CreditImporterCore do
    subject{CreditImporterCore}

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

        it "creates actions to insert all the titles" do
          success = subject.(fetch_credits, find_title)
          expect(success.success?).to eq(true)

          actions = success.result

          expect(actions.length).to eq(163)
          expect(actions.all?{|a| InsertTitle === a}).to be(true)
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

        it "inserts and updates the titles" do
          success = subject.(fetch_credits, find_title)
          expect(success.success?).to eq(true)

          actions = success.result
          expect(actions.length).to eq(163)

          grouped_actions = actions.group_by(&:class)
          expect(grouped_actions[InsertTitle].length).to eq(162)
          expect(grouped_actions[UpdateTitle].length).to eq(1)

          forest_update = grouped_actions[UpdateTitle].first
          expect(forest_update.title).to eq("forest gump")
          expect(forest_update.update_attrs).to be_instance_of(Hash)
        end
      end
    end
  end
end