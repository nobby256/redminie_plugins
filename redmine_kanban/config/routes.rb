#ActionController::Routing::Routes.draw do |map|
#  map.resource :kanban, :member => {:sync => :put}
#end
# Plugin's routes
RedmineApp::Application.routes.draw do
  get '/kanbans', :controller => :kanbans, :action => 'show'
  resource :kanban do
    member do
      put 'sync'
    end
  end
=begin
  scope '/projects/:project_id/kanbans' do
    get 'show', :controller => :kanbans, :action => 'show'
  end
=end
end
