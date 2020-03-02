module V03
  module Result
    Success = Value.new(:result) do
      def success?
        true
      end

      def failure?
        false
      end
    end

    Failure = Value.new(:message) do
      def success?
        false
      end

      def failure?
        true
      end
    end
  end
end