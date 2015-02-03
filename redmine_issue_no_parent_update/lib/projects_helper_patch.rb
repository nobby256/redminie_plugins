require_dependency 'projects_helper'

module IssueNoParentUpdate
  module ProjectsHelperPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :project_settings_tabs, :sub_categories

      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def project_settings_tabs_with_sub_categories
        tabs = project_settings_tabs_without_sub_categories
        action = {:name => 'sub_categories', 
          :controller => 'issue_sub_categories',
          :action => :index, 
          :partial => 'projects/settings/issue_sub_categories', :label => :label_issue_sub_categories}
        tabs << action if User.current.allowed_to?(:manage_categories, @project)
        tabs
      end
    end
  end
end