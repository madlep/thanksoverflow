module V03::Core
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

  ImportSummary = Value.new(
    :inserted_count,
    :updated_count,
    :error_count
  )
end