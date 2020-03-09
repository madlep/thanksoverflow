Rails.application.routes.draw do
  %w{v01 v02 v03 v04 v05 v06 v07}.each do |v|
    namespace v do
      get 'admin/', to: 'admin#index'
      post 'admin/import_credits', to: 'admin#import_credits'
      delete 'admin/reset_credits', to: 'admin#reset_credits'
    end
  end
end
