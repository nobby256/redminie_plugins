# Plugin's routes
RedmineApp::Application.routes.draw do
  scope '/version_burndown_charts' do
    get '/:project_id' => 'version_burndown_charts#index'
    get '/:project_id/graph_data/:version_id' => 'version_burndown_charts#get_graph_data'
  end
end