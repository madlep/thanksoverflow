require 'rails_helper'

RSpec.describe V04::Core do
  describe V04::Core::Success do
    it "has success? true" do
      expect(V04::Core::Success.new("I'm a success").success?).to eq(true)
    end

    it "has failure? false" do
      expect(V04::Core::Success.new("I'm a success").failure?).to eq(false)
    end

    it "can chain operations with and_then" do
      result = V04::Core::Success.new("foo")
      .and_then{ |foo| V04::Core::Success.new(foo + "bar") }
      .and_then{ |foobar| V04::Core::Success.new(foobar + "baz") }

      expect(result).to eq(V04::Core::Success.new("foobarbaz"))
    end
  end

  describe V04::Core::Failure do
    it "has success? false" do
      expect(V04::Core::Failure.new("I'm a failure").success?).to eq(false)
    end

    it "has failure? true" do
      expect(V04::Core::Failure.new("I'm a failure").failure?).to eq(true)
    end

    it "can halt operations with and_then" do
      result = V04::Core::Failure.new("fuz")
      .and_then{ |foo| V04::Core::Success.new(foo + "bar") }
      .and_then{ |foobar| V04::Core::Success.new(foobar + "baz") }

      expect(result).to eq(V04::Core::Failure.new("fuz"))
    end
  end
end