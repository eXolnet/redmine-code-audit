# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources :projects do
        resources :audits
end

get '/projects/:project_id/audits', :to => 'audits#index'
get '/projects/:project_id/audits/new', :to => 'audits#new'
post '/projects/:project_id/audits', :to => 'audits#create'
get '/projects/:project_id/audits/:id', :to => 'audits#show'
post '/projects/:project_id/audits/:id', :to => 'audits#comment'
get '/projects/:project_id/audits/:id/edit', :to => 'audits#edit'
post '/projects/:project_id/audits/:id/edit', :to => 'audits#update'
delete '/projects/:project_id/audits/:id', :to => 'audits#destroy'
match '/changesets/auto_complete', :to => 'audits#changesets', :via => :get, :as => 'auto_complete_changesets'