module V07
  class CreditImporterShell
    include Result
    include Actions

    def initialize(person_id:, api_key:)
      @person_id = person_id
      @api_key = api_key
    end

    def import()
      CreditImporterCore.(
        method(:fetch_credits),
        method(:find_title)
      ).and_then(&method(:handle_actions).curry.(ImportSummary.empty()))
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

    def handle_actions(import_summary, actions)
      actions.reduce(import_summary){|summary, action|
        case action
        in InsertTitle[insert_attrs]
          insert_title(summary, insert_attrs)
        in UpdateTitle[title, update_attrs]
          update_title(summary, title, update_attrs)
        end
      }.then{|final_summary|
        Result.of(final_summary)
      }
    end

    def insert_title(summary, **insert_attrs)
      title = Title.new(**insert_attrs)
      if title.valid?
        title.save!
        summary.inserted()
      else
        summary.errored()
      end
    end

    def update_title(summary, title, **update_attrs)
      title.attributes = update_attrs
      if title.valid?
        title.save!
        summary.updated()
      else
        summary.errored()
      end
    end
  end
end