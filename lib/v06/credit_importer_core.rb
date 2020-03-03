module V06
  module CreditImporterCore
    include Result
    include Option

    module_function

    def call(fetch_credits, find_title, insert_title, update_title, import_summary)
      fetch_credits.()
        .and_then(&method(:parse_credits))
        .and_then(&method(:import_credits).curry.(import_summary, find_title, insert_title, update_title))
    end

    def parse_credits(credits_json)
      Result.of { JSON.parse(credits_json) }
    end

    def import_credits(import_summary, find_title, insert_title, update_title, credits)
      credits["cast"]
      .reduce(import_summary, &method(:create_or_update_title).curry.(find_title, insert_title, update_title))
      .then(){|final_summary| Result.of(final_summary)}
    end

    def create_or_update_title(find_title, insert_title, update_title, import_summary, cast_entry)
      case find_title.(cast_entry["id"])
      in None
        do_insert(insert_title, import_summary, cast_entry)
      in Some[title]
        do_update(update_title, import_summary, cast_entry, title)
      end
    end

    def do_insert(insert_title, import_summary, cast_entry)
      case insert_title.(
        tmdb_id: cast_entry["id"],
        title: cast_entry["title"],
        character: cast_entry["character"],
        release_date: cast_entry["release_date"],
        media_type: cast_entry["media_type"],
        popularity: cast_entry["popularity"],
        synced_at: DateTime.now
      )
      in Success
        import_summary.inserted()
      in Failure
        import_summary.errored()
      end
    end

    def do_update(update_title, import_summary, cast_entry, title)
      case update_title.(title, popularity: cast_entry["popularity"], synced_at: DateTime.now)
      in Success
        import_summary.updated()
      in Failure
        import_summary.errored()
      end
    end
  end
end