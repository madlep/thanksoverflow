class V03::AdminController < ActionController::Base
  THANKS_ID = 31

  def index
    render 'admin/index'
  end

  def import_credits
    importer = V03::CreditImporter.new(
      person_id: THANKS_ID,
      api_key: Rails.configuration.tmdb_api_key
    )
    result = importer.import()

    if result.success?
      result = result.result
      flash[:notice] = "Imported #{result.inserted_count} new credits, updated #{result.updated_count}"
      flash[:error] = "#{result.error_count} titles had errors preventing saving" if result.error_count > 0
      redirect_to action: :index
    else
      flash[:error] = result.message
    end
  end

  def reset_credits
    deleted_count = Title.delete_all
    flash[:notice] = "Deleted #{deleted_count} titles"
    redirect_to action: :index
  end
end 