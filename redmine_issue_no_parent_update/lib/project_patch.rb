require_dependency 'project'

module IssueNoParentUpdate
  module ProjectPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :copy, :wf

        has_many :issue_sub_categories, :dependent => :delete_all, :order => "#{IssueSubCategory.table_name}.position"

      end
    end

    module InstanceMethods
     
       def copy_with_wf(project, options={})
        project = project.is_a?(Project) ? project : Project.find(project)

        to_be_copied = %w(wiki versions issue_categories issues members queries boards issue_sub_categories)
        to_be_copied = to_be_copied & options[:only].to_a unless options[:only].nil?

        Project.transaction do
          if save
            reload
            to_be_copied.each do |name|
              send "copy_#{name}", project
            end
            Redmine::Hook.call_hook(:model_project_copy_before_save, :source_project => project, :destination_project => self)
            save
          end
        end
      end

      def copy_issue_sub_categories(project)
        project.issue_categories.each do |issue_category|
          new_issue_category = IssueCategory.new
          new_issue_category.attributes = issue_category.attributes.dup.except("id", "project_id")
          self.issue_categories << new_issue_category
        end
      end
    end
  end
end
