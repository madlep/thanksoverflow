module V04
  class CreditImporter
    include Result

    def initialize(person_id:, api_key:)
      @person_id = person_id
      @api_key = api_key
    end

    def import()
      fetch_credits()
        .and_then(&method(:parse_credits))
        .and_then(){|credits|
          credits["cast"]
          .reduce(ImportSummary.new(0,0,0), &method(:create_or_update_title))
          .then(){|final_summary|
            Success.new(final_summary)
          }
        }
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

    def create_or_update_title(import_summary, cast_entry)
      title = Title.where(tmdb_id: cast_entry["id"]).first
      if title
        title.update( popularity: cast_entry["popularity"], synced_at: DateTime.now)
        import_summary.updated()
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
          import_summary.inserted()
        else
          import_summary.errored()
        end
      end
    end
  end
end