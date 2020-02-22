Rails.application.routes.draw do
  get 'v01/admin/', to: 'v01/admin#index'
  post 'v01/admin/import_credits', to: 'v01/admin#import_credits'
end
