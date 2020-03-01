class V05::CreditImporterCore
  include V05::Core

  def call(fetch_credits, find_title, import_summary)
    fetch_credits.()
      .and_then(&method(:parse_credits))
      .and_then(&method(:import_credits).curry.(import_summary, find_title))
  end

  def parse_credits(credits_json)
    begin
      Success.new(JSON.parse(credits_json))
    rescue JSON::ParserError => e
      Failure.new(e)
    end
  end

  def import_credits(import_summary, find_title, credits)
    credits["cast"]
    .reduce(import_summary, &method(:create_or_update_title).curry.(find_title))
    .then{|final_summary|
      Success.new(final_summary)
    }
  end

  def create_or_update_title(find_title, import_summary, cast_entry)
    title = find_title.(cast_entry["id"])
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