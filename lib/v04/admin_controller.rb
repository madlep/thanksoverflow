class V04::AdminController < ActionController::Base
  THANKS_ID = 31

  def index
    render 'admin/index'
  end

  def import_credits
    importer = V04::CreditImporter.new(
      person_id: THANKS_ID,
      api_key: Rails.configuration.tmdb_api_key
    )

    case importer.import()
    in V04::Core::Success[
      V04::Core::ImportSummary[inserted_count, updated_count, error_count]
    ]
      flash[:notice] = "Imported #{inserted_count} new credits, updated #{updated_count}"
      flash[:error] = "#{error_count} titles had errors preventing saving" if error_count > 0
    in V04::Core::Failure[message]
      flash[:error] = "Fatal error prevented import: #{message.inspect}"
    end
    redirect_to action: :index
  end

  def reset_credits
    deleted_count = Title.delete_all
    flash[:notice] = "Deleted #{deleted_count} titles"
    redirect_to action: :index
  end
end 