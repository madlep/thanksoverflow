module V04
  module Result
    describe Success do
      it "has success? true" do
        expect(Success.new("I'm a success").success?).to eq(true)
      end

      it "has failure? false" do
        expect(Success.new("I'm a success").failure?).to eq(false)
      end

      it "can chain operations with and_then" do
        result = Success.new("foo")
        .and_then{ |foo| Success.new(foo + "bar") }
        .and_then{ |foobar| Success.new(foobar + "baz") }

        expect(result).to eq(Success.new("foobarbaz"))
      end
    end

    describe Failure do
      it "has success? false" do
        expect(Failure.new("I'm a failure").success?).to eq(false)
      end

      it "has failure? true" do
        expect(Failure.new("I'm a failure").failure?).to eq(true)
      end

      it "can halt operations with and_then" do
        result = Failure.new("fuz")
        .and_then{ |foo| Success.new(foo + "bar") }
        .and_then{ |foobar| Success.new(foobar + "baz") }

        expect(result).to eq(Failure.new("fuz"))
      end
    end
  end
end