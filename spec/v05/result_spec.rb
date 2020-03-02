require 'rails_helper'

RSpec.describe V05::Result do

  describe V05::Result::Success do
    it "has success? true" do
      expect(V05::Result::Success.new("I'm a success").success?).to eq(true)
    end

    it "has failure? false" do
      expect(V05::Result::Success.new("I'm a success").failure?).to eq(false)
    end

    it "can chain operations with and_then" do
      result = V05::Result::Success.new("foo")
      .and_then{ |foo| V05::Result::Success.new(foo + "bar") }
      .and_then{ |foobar| V05::Result::Success.new(foobar + "baz") }

      expect(result).to eq(V05::Result::Success.new("foobarbaz"))
    end
  end

  describe V05::Result::Failure do
    it "has success? false" do
      expect(V05::Result::Failure.new("I'm a failure").success?).to eq(false)
    end

    it "has failure? true" do
      expect(V05::Result::Failure.new("I'm a failure").failure?).to eq(true)
    end

    it "can halt operations with and_then" do
      result = V05::Result::Failure.new("fuz")
      .and_then{ |foo| V05::Result::Success.new(foo + "bar") }
      .and_then{ |foobar| V05::Result::Success.new(foobar + "baz") }

      expect(result).to eq(V05::Result::Failure.new("fuz"))
    end
  end
end