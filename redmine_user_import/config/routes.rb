RedmineApp::Application.routes.draw do
  scope 'user_import' do
    get 'index', :controller => 'user_import', :action => 'index'
    post 'match', :controller => 'user_import', :action => 'match'
    post 'result', :controller => 'user_import', :action => 'result'
  end
end
