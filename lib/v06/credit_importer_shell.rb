module V06
  class CreditImporterShell
    include Result

    def initialize(person_id:, api_key:)
      @person_id = person_id
      @api_key = api_key
    end

    def import()
      CreditImporterCore.(
        method(:fetch_credits),
        method(:find_title),
        method(:insert_title),
        method(:update_title),
        ImportSummary.new(0,0,0)
      )
    end

    def fetch_credits()
      Result.of {
        url = "https://api.themoviedb.org/3/person/#{@person_id}/combined_credits?api_key=#{@api_key}&language=en-US"
        response = HTTP.get(url)
        if response.status.success?
          Success.new(response.to_s)
        else
          Failure.new("error fetching credits. Status=#{response.status}")
        end
      }
    end

    def find_title(tmdb_id)
      Option.of(Title.where(tmdb_id: tmdb_id).first)
    end

    def insert_title(**insert_attrs)
      title = Title.new(**insert_attrs)
      if title.valid?
        title.save!
        Success.new(title)
      else
        Failure.new(title)
      end
    end

    def update_title(title, **update_attrs)
      title.attributes = update_attrs
      if title.valid?
        title.save!
        Success.new(title)
      else
        Failure.new(title)
      end
    end
  end
end