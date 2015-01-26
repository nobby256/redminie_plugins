# Plugin's routes
RedmineApp::Application.routes.draw do
  scope '/projects/:project_id/importer' do
    post 'match', :controller => :importer, :action => 'match'
    post 'result', :controller => :importer, :action => 'result'
  end
end
