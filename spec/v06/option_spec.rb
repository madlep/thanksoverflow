require 'rails_helper'

module V06
  module Option
    describe ".of" do
      it "constructs Some when value is not nil" do
        expect(Option.of("foobar")).to eq(Some.new("foobar"))
      end

      it "returns none when value is nil" do
        expect(Option.of(nil)).to eq(None)
      end
    end

    describe Some do
      it "has some? true" do
        expect(Some.new("I'm a some").some?).to eq(true)
      end

      it "has none? false" do
        expect(Some.new("I'm a some").none?).to eq(false)
      end

      it "can chain operations with and_then" do
        option = Some.new("foo")
        .and_then{ |foo| Some.new(foo + "bar") }
        .and_then{ |foobar| Some.new(foobar + "baz") }

        expect(option).to eq(Some.new("foobarbaz"))
      end
    end

    describe None do
      it "has some? false" do
        expect(None.new().some?).to eq(false)
      end

      it "has none? true" do
        expect(None.new().none?).to eq(true)
      end

      it "can halt operations with and_then" do
        option = None.new()
        .and_then{ |foo| Some.new(foo + "bar") }
        .and_then{ |foobar| Some.new(foobar + "baz") }

        expect(option).to eq(None.new())
      end

      it "has case equality with any None" do
        result = None.new
        case result
        in None => none
          expect(none === None.new)
        else
          raise "should not get here"
        end

        expect(None.new === None.new).to eq(true)
        expect(None === None.new).to eq(true)
        expect(None.new === None).to eq(true)
      end
    end
  end
end