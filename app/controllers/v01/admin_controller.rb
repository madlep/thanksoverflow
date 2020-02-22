class V01::AdminController < ActionController::Base
  def index
    render 'admin/index'
  end

  def import_credits
    thanks_id = 31
    api_key = ENV["TMDB_API_KEY"] || "HARDCODEDAPIKEY"
    url = "https://api.themoviedb.org/3/person/#{thanks_id}/combined_credits?api_key=#{api_key}&language=en-US"
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
    flash[:notice] = "Imported #{inserted_count} new credits, updated #{updated_count}"
    flash[:error] = "#{error_count} titles had errors preventing saving" if error_count > 0
    redirect_to action: :index
  end
end 