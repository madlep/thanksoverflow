class V05::CreditImporterShell
  include V05::Core

  def initialize(person_id:, api_key:)
    @person_id = person_id
    @api_key = api_key
  end

  def import()
    V05::CreditImporterCore.new.(
      method(:fetch_credits),
      method(:find_title),
      ImportSummary.new(0,0,0)
    )
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

  def find_title(tmdb_id)
    Title.where(tmdb_id: tmdb_id).first
  end
end