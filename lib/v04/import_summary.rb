module V04
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