require 'rails_helper'

RSpec.describe V05::CreditImporterShell do
  let(:person_id) { 31 }
  let(:api_key) { "ABC123" }
  let(:expected_url) { "https://api.themoviedb.org/3/person/31/combined_credits?api_key=ABC123&language=en-US" }
  subject{ described_class.new(person_id: person_id, api_key: api_key) }

  describe "#import" do
    it "delegates to core" do
      expect(V05::CreditImporterCore).to receive(:call).with(
        subject.method(:fetch_credits),
        subject.method(:find_title),
        V05::Core::ImportSummary.new(0,0,0)
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
        expect(subject.fetch_credits()).to eq(V05::Core::Success.new("It worked"))
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

      expect(subject.find_title(tmdb_id)).to eq("result")
    end
  end
end