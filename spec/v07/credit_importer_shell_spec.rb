require 'rails_helper'

module V07
  include Option
  include Result

  RSpec.describe CreditImporterShell do

    let(:person_id) { 31 }
    let(:api_key) { "ABC123" }
    let(:expected_url) { "https://api.themoviedb.org/3/person/31/combined_credits?api_key=ABC123&language=en-US" }
    subject{ described_class.new(person_id: person_id, api_key: api_key) }

    describe "#import" do
      it "delegates to core" do
        expect(CreditImporterCore).to receive(:call).with(
          subject.method(:fetch_credits),
          subject.method(:find_title),
        ).and_return(Result.of([]))
        subject.import()
      end

      describe "actions returned by core" do
        before do
          expect(HTTP).to receive(:get).and_return(
            HTTP::Response.new(
              status: 200,
              version: 1.1,
              body: File.read("spec/fixtures/person_31_combined_credits.json")
            )
          )
        end

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

        it "are handled by shell" do 
          expect(Title.count).to eq(1)
          success = subject.import()
          expect(Title.count).to eq(104)

          expect(success.success?).to eq(true)

          result = success.result

          expect(result.inserted_count).to eq(103)
          expect(result.updated_count).to eq(1)
          expect(result.error_count).to eq(59)
        end
      end
    end

    describe "#fetch_credits" do
      describe "when HTTP response succeeds" do
        before do
          expect(HTTP).to receive(:get).with(expected_url).and_return(
            HTTP::Response.new(
              status: 200,
              version: 1.1,
              body: "It worked"
            )
          )
        end

        it "returns success with body" do
          expect(subject.fetch_credits()).to eq(Success.new("It worked"))
        end
      end

      describe "when http call returns non success" do
        before do
          expect(HTTP).to receive(:get).with(expected_url).and_return(
            HTTP::Response.new(
              status: 500,
              version: 1.1,
              body: "something broke"
            )
          )
        end

        it "returns a failure value" do
          failure = subject.import()
          expect(failure.failure?).to eq(true)
          expect(failure.message).to eq("error fetching credits. Status=500 Internal Server Error")
        end
      end

      describe "when http call errors" do
        before do
          expect(HTTP).to receive(:get).with(expected_url).and_raise(HTTP::Error.new("foo was too bar"))
        end

        it "returns a failure value" do
          failure = subject.import()
          expect(failure.failure?).to eq(true)
          expect(failure.message).to be_instance_of(HTTP::Error)
        end
      end
    end

    describe "#find_title" do
      describe "finds title in database" do
        it "returns Some with title" do
          tmdb_id = 123
          rel = double(first: "result")
          expect(Title).to receive(:where).with(tmdb_id: tmdb_id).and_return(rel)

          expect(subject.find_title(tmdb_id)).to eq(Some.new("result"))
        end
      end
    end

    describe "#handle_actions" do
      describe "with InsertTitle action" do
        it "delegates to insert_title" do
          insert_attrs = {character: "T. Hanks"}
          insert = InsertTitle.new(insert_attrs)
          import_summary = ImportSummary.empty()
          expect(subject).to receive(:insert_title).with(import_summary, insert_attrs)
          subject.handle_actions(import_summary, [insert])
        end
      end

      describe "with UpdateTitle action" do
        it "delegates to update_title" do
          title = Title.new(id: 123)
          update_atts = {character: "T. Hanks"}
          update = UpdateTitle.new(title, update_atts)
          import_summary = ImportSummary.empty()
          expect(subject).to receive(:update_title).with(import_summary, title, update_atts)
          subject.handle_actions(import_summary, [update])
        end
      end
    end

    describe "#insert_title" do
      let(:valid_insert_attrs) {
        {
          tmdb_id: 13,
          title: "Forrest Gump",
          character: "Forrest Gump",
          release_date: "1994-07-06",
          media_type: "movie",
          popularity: 0.31462e2,
          synced_at: "2020-02-22 03:48:06"
        }
      }

      let(:invalid_insert_attrs) {
        {
          tmdb_id: 13,
          title: nil,
          character: "Forrest Gump",
          release_date: "1994-07-06",
          media_type: "movie",
          popularity: 0.31462e2,
          synced_at: "2020-02-22 03:48:06"
        }
      }

      it "inserts title if it is valid from supplied attributes" do
        subject.insert_title(ImportSummary.empty(), valid_insert_attrs)
        expect(Title.where(tmdb_id: 13).exists?).to be(true)
      end

      it "increments summary inserted if it is valid from supplied attributes" do
        summary = subject.insert_title(ImportSummary.empty(), valid_insert_attrs)
        expect(summary.inserted_count).to eq(1)
      end

      it "returns Failure if it is not valid from supplied attributes" do
        summary = subject.insert_title(ImportSummary.empty(), invalid_insert_attrs)
        expect(summary.error_count).to eq(1)
      end
    end

    describe "#update_title" do
      before do
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

      let(:title) { 
        Title.where(tmdb_id: 13).first
      }

      it "updates title if it is valid from supplied attributes" do
        subject.update_title(ImportSummary.empty(), title, popularity: 123)
        expect(Title.where(tmdb_id: 13).first.popularity).to eq(123)
      end

      it "returns Success if it is valid from supplied attributes" do
        summary = subject.update_title(ImportSummary.empty(), title, character: "Borest Bump")
        expect(summary.updated_count).to eq(1)
      end

      it "returns Failure if it is not valid from supplied attributes" do
        summary = subject.update_title(ImportSummary.empty(), title, title: nil)
        expect(summary.error_count).to eq(1)
      end
    end
  end
end