module V03
  class CreditImporter
    include Result

    def initialize(person_id:, api_key:)
      @person_id = person_id
      @api_key = api_key
    end

    def import()
      fetch_credits_result = fetch_credits()
      if fetch_credits_result.failure?
        return fetch_credits_result
      else
        parse_credits_result = parse_credits(fetch_credits_result.result)
        if parse_credits_result.failure?
          return parse_credits_result
        else
          import_summary = ImportSummary.new(0,0,0)
          parse_credits_result.result["cast"].each do |cast_entry|
            import_summary = create_or_update_title(cast_entry, import_summary)
          end
          Success.new(import_summary)
        end
      end
    end

    private
    def fetch_credits()
      url = "https://api.themoviedb.org/3/person/#{@person_id}/combined_credits?api_key=#{@api_key}&language=en-US"
      response = HTTP.get(url)
      if response.status.success?
        Success.new(response.to_s)
      else
        Failure.new("error fetching credits. Status=#{response.status}")
      end
    rescue HTTP::Error => e
      Failure.new(e)
    end

    def parse_credits(credits_json)
      begin
        Success.new(JSON.parse(credits_json))
      rescue JSON::ParserError => e
        Failure.new(e)
      end
    end

    def create_or_update_title(cast_entry, import_summary)
      title = Title.where(tmdb_id: cast_entry["id"]).first
      if title
        title.update( popularity: cast_entry["popularity"], synced_at: DateTime.now)
        import_summary.with(updated_count: import_summary.updated_count + 1)
      else
        title = Title.new(
          tmdb_id: cast_entry["id"],
          title: cast_entry["title"],
          character: cast_entry["character"],
          release_date: cast_entry["release_date"],
          media_type: cast_entry["media_type"],
          popularity: cast_entry["popularity"],
          synced_at: DateTime.now
        )
        if title.valid?
          title.save!
          import_summary.with(inserted_count: import_summary.inserted_count + 1)
        else
          import_summary.with(error_count: import_summary.error_count + 1)
        end
      end
    end
  end
end