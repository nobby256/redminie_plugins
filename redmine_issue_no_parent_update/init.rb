require_dependency 'issue_no_parent_update_patch'

Rails.configuration.to_prepare do
  require_dependency 'issue'
  Issue.send(:include, IssueNoParentUpdatePatch)
end

Redmine::Plugin.register :redmine_issue_no_parent_update do
  name 'Redmine Issue No Parent Update plugin'
  author 'Nobby256'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'

  requires_redmine :version => '2.6.0'
end
