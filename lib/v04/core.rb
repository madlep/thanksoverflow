module V04::Core
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

  ImportSummary = Value.new(
    :inserted_count,
    :updated_count,
    :error_count
  ) do
    def inserted()
      self.with(inserted_count: self.inserted_count + 1)
    end

    def updated()
      self.with(updated_count: self.updated_count + 1)
    end

    def errored()
      self.with(error_count: self.error_count + 1)
    end
  end
end