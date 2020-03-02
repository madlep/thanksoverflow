module V04
  module Result
    Success = Value.new(:result) do
      def success?
        true
      end

      def failure?
        false
      end

      def and_then(&callback)
        callback.(self.result)
      end
    end

    Failure = Value.new(:message) do
      def success?
        false
      end

      def failure?
        true
      end

      def and_then(&_callback)
        self
      end
    end
  end
end