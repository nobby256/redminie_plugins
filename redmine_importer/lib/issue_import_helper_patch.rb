require_dependency 'projects_helper'

module IssueImportHelperPatch
  def self.included(base)
    base.send(:include, ProjectsHelperMethodsIssueImport)
    base.class_eval do
      alias_method_chain :project_settings_tabs, :issue_import
    end
  end
end

module ProjectsHelperMethodsIssueImport
  # Append tab for issue templates to project settings tabs.
  def project_settings_tabs_with_issue_import
    tabs = project_settings_tabs_without_issue_import
    action = {:name => 'issue_import', 
      :controller => 'importer',
      :action => :index, 
      :partial => 'importer/index', :label => :label_issue_importer}
    tabs << action if User.current.allowed_to?(action, @project)
    tabs
  end
end



