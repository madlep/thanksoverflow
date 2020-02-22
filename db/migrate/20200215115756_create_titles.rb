class CreateTitles < ActiveRecord::Migration[6.0]
  def change
    create_table :titles do |t|
      t.integer :tmdb_id, null: false
      t.string :title, null: false
      t.string :character, null: false
      t.date :release_date, null: false
      t.string :media_type, null: false
      t.decimal :popularity, null: false
      t.datetime :synced_at, null: false
      t.timestamps
    end
  end
end
