# Plugin's routes
RedmineApp::Application.routes.draw do

  resources :projects do
    shallow do
      resources :issue_sub_categories
    end
  end

end
