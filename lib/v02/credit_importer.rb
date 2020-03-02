module V02
  class CreditImporter
    def initialize(person_id:, api_key:)
      @person_id = person_id
      @api_key = api_key
    end

    def import()
      url = "https://api.themoviedb.org/3/person/#{@person_id}/combined_credits?api_key=#{@api_key}&language=en-US"
      inserted_count = updated_count = error_count = 0
      JSON.parse(HTTP.get(url).to_s)["cast"].each do |cast_entry|
        title = Title.where(tmdb_id: cast_entry["id"]).first
        if title
          title.update( popularity: cast_entry["popularity"], synced_at: DateTime.now)
          updated_count += 1
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
            inserted_count += 1
          else
            error_count += 1
          end
        end
      end
      [inserted_count, updated_count, error_count]
    end
  end
end