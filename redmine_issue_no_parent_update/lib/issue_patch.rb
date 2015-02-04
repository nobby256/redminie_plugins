require_dependency 'issue'

module IssueNoParentUpdate
  module IssuePatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        belongs_to :sub_category, :class_name => 'IssueSubCategory', :foreign_key => 'sub_category_id'
        safe_attributes 'external_id', 'external_order', 'tag', 'sub_category_id', :if => lambda {|issue, user| issue.new_record? || user.allowed_to?(:edit_issues, issue.project) }

      end
    end

    module ClassMethods
    end

    module InstanceMethods
    end
  end
end