require 'rails_helper'

module V06
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
          subject.method(:insert_title),
          subject.method(:update_title),
          ImportSummary.new(0,0,0)
        )
        subject.import()
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
      it "checks database to find title" do
        tmdb_id = 123
        rel = double(first: "result")
        expect(Title).to receive(:where).with(tmdb_id: tmdb_id).and_return(rel)

        expect(subject.find_title(tmdb_id)).to eq(Some.new("result"))
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
        subject.insert_title(valid_insert_attrs)
        expect(Title.where(tmdb_id: 13).exists?).to be(true)
      end

      it "returns Success if it is valid from supplied attributes" do
        result = subject.insert_title(valid_insert_attrs)
        expect(result).to be_instance_of(Success)
      end

      it "returns Failure if it is not valid from supplied attributes" do
        result = subject.insert_title(invalid_insert_attrs)
        expect(result).to be_instance_of(Failure)
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
        subject.update_title(title, popularity: 123)
        expect(Title.where(tmdb_id: 13).first.popularity).to eq(123)
      end

      it "returns Success if it is valid from supplied attributes" do
        result = subject.update_title(title, character: "Borest Bump")
        expect(result).to be_instance_of(Success)
      end

      it "returns Failure if it is not valid from supplied attributes" do
        result = subject.update_title(title, title: nil)
        expect(result).to be_instance_of(Failure)
      end
    end
  end
end