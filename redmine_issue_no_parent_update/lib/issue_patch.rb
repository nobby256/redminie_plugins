require_dependency 'issue'

module IssueNoParentUpdate
  module IssuePatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        belongs_to :sub_category, :class_name => 'IssueSubCategory', :foreign_key => 'sub_category_id'

      end
    end

    module ClassMethods
    end

    module InstanceMethods
    end
  end
end