Rails.application.routes.draw do
  get 'v01/admin/', to: 'v01/admin#index'
  post 'v01/admin/import_credits', to: 'v01/admin#import_credits'
  delete 'v01/admin/reset_credits', to: 'v01/admin#reset_credits'
end
