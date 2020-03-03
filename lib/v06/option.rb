module V06
  module Option
    module_function

    def of(value)
      if !value.nil?
        Some.new(value)
      else
        None
      end
    end

    Some = Value.new(:result) do
      def some?
        true
      end

      def none?
        false
      end

      def and_then(&callback)
        callback.(self.result)
      end
    end

    class None
      class << self
        def new
          self
        end

        def some?
          false
        end

        def none?
          true
        end

        def and_then(&_callback)
          self
        end

        def ===(other)
          self == other
        end
      end
    end
  end
end