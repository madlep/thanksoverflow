module V07
  module CreditImporterCore
    include Result
    include Option
    include Actions

    module_function

    def call(fetch_credits, find_title)
      fetch_credits.()
        .and_then(&method(:parse_credits))
        .and_then(&method(:import_credits).curry.(find_title))
    end

    def parse_credits(credits_json)
      Result.of { JSON.parse(credits_json) }
    end

    def import_credits(find_title, credits)
      credits["cast"]
      .reduce([], &method(:create_or_update_title).curry.(find_title))
      .then(){|generated_actions| Result.of(generated_actions)}
    end

    def create_or_update_title(find_title, actions, cast_entry)
      action = case find_title.(cast_entry["id"])
      in None
        InsertTitle.new(
          tmdb_id: cast_entry["id"],
          title: cast_entry["title"],
          character: cast_entry["character"],
          release_date: cast_entry["release_date"],
          media_type: cast_entry["media_type"],
          popularity: cast_entry["popularity"],
          synced_at: DateTime.now
        )
      in Some[title]
        UpdateTitle.new(
          title,
          popularity: cast_entry["popularity"],
          synced_at: DateTime.now
        )
      end
      actions + [action]
    end
  end
end