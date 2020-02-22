Rails.application.routes.draw do
  namespace 'v01' do
    get 'admin/', to: 'admin#index'
    post 'admin/import_credits', to: 'admin#import_credits'
    delete 'admin/reset_credits', to: 'admin#reset_credits'
  end
end
