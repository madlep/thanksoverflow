require 'rails_helper'

module V02
  RSpec.describe CreditImporter do
    let(:person_id) { 31 }
    let(:api_key) { "ABC123" }
    subject{ described_class.new(person_id: person_id, api_key: api_key) }

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

      describe "and there are no titles in the database" do
        it "inserts all the titles" do
          expect(Title.count).to eq(0)
          inserted_count, updated_count, error_count = subject.import()
          expect(Title.count).to eq(104)

          expect(inserted_count).to eq(104)
          expect(updated_count).to eq(0)
          expect(error_count).to eq(59)
        end
      end

      describe "and there are already some titles in the database" do
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

        it "inserts all the titles" do
          expect(Title.count).to eq(1)
          inserted_count, updated_count, error_count = subject.import()
          expect(Title.count).to eq(104)

          expect(inserted_count).to eq(103)
          expect(updated_count).to eq(1)
          expect(error_count).to eq(59)
        end
      end
    end

    describe "when http call returns non success" do
      before do
        expect(HTTP).to receive(:get).and_return(
          HTTP::Response.new(
            status: 500,
            version: 1.1,
            body: "something broke"
          )
        )
      end

      it "just doesn't do anything, and tries to parse bad JSON" do
        expect { subject.import() }.to raise_error(JSON::ParserError)
      end
    end

    describe "when http call errors" do
      before do
        expect(HTTP).to receive(:get).and_raise(HTTP::Error)
      end

      it "just doesn't do anything, and just bubbles up the error" do
        expect { subject.import() }.to raise_error(HTTP::Error)
      end
    end

    describe "when JSON parsing errors" do
      before do
        expect(HTTP).to receive(:get).and_return(
          HTTP::Response.new(
            status: 200,
            version: 1.1,
            body: File.read("spec/fixtures/person_31_combined_credits.json")
          )
        )
      end

      before do
        expect(JSON).to receive(:parse).and_raise(JSON::ParserError)
      end

      it "just doesn't do anything, and just bubbles up the error" do
        expect { subject.import() }.to raise_error(JSON::ParserError)
      end
    end
  end
end