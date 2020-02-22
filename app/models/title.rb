class Title < ApplicationRecord
  validates_presence_of :tmdb_id,
                        :release_date,
                        :title,
                        :character,
                        :release_date,
                        :media_type,
                        :popularity,
                        :synced_at
end
