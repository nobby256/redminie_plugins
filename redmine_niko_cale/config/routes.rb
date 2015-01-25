RedmineApp::Application.routes.draw do
  get 'projects/:project_id/niko_cale', :controller => 'niko_cale', :action => 'index'
  get 'projects/:project_id/feelings', :controller => 'feelings', :action => 'show'
  post 'feelings/edit_comment/:id', :controller => 'feelings', :action => 'edit_comment'
  get 'niko_cale_settings/preview', :controller => 'niko_cale_settings', :action => 'preview'
  resources :feelings 
end