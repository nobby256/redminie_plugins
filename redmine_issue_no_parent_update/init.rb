require_dependency 'issue_no_parent_update_patch'
require_dependency 'issue_no_parent_update_listener'
require_dependency 'issue_patch'
require_dependency 'issue_query_patch'
require_dependency 'project_patch'
require_dependency 'queries_helper_patch'
require_dependency 'projects_helper_patch'

Rails.configuration.to_prepare do
  require_dependency 'issue'
  require_dependency 'issue_sub_category'
  require_dependency 'project'

  Issue.send(:include, IssueNoParentUpdatePatch)
  Issue.send(:include, IssueNoParentUpdate::IssuePatch)
  IssueQuery.send(:include, IssueNoParentUpdate::IssueQueryPatch)
  QueriesHelper.send(:include, IssueNoParentUpdate::QueriesHelperPatch)
  Project.send(:include, IssueNoParentUpdate::ProjectPatch)
  ProjectsHelper.send(:include, IssueNoParentUpdate::ProjectsHelperPatch)
end

Redmine::Plugin.register :redmine_issue_no_parent_update do
  name 'Redmine Issue No Parent Update plugin'
  author 'Nobby256'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'

  requires_redmine :version => '2.6.0'

  project_module :issue_tracking do
    permission :manage_sub_categories, {:projects => :settings, :issue_sub_categories => [:index, :show, :new, :create, :edit, :update, :destroy]}, :require => :member
#    permission :view_issue_view_stats, issue_view_stats: [:view_stats]
  end

end
