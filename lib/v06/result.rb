module V06
  module Result
    module_function

    def of(value = nil)
      if block_given?
        value = begin
          yield
        rescue StandardError => e
          e
        end
      end

      case value
      in Success | Failure => result
        result
      in StandardError => error
        Failure.new(error)
      in result
        Success.new(result)
      end
    end

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