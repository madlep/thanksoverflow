class V02::AdminController < ActionController::Base
  THANKS_ID = 31

  def index
    render 'admin/index'
  end

  def import_credits
    importer = V02::CreditImporter.new(
      person_id: THANKS_ID,
      api_key: Rails.configuration.tmdb_api_key
    )
    inserted_count, updated_count, error_count = importer.import()

    flash[:notice] = "Imported #{inserted_count} new credits, updated #{updated_count}"
    flash[:error] = "#{error_count} titles had errors preventing saving" if error_count > 0
    redirect_to action: :index
  end

  def reset_credits
    deleted_count = Title.delete_all
    flash[:notice] = "Deleted #{deleted_count} titles"
    redirect_to action: :index
  end
end 