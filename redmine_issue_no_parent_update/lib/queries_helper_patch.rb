require_dependency 'issue'

module IssueNoParentUpdate
  module QueriesHelperPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :column_value, :wf

      end
    end

    module InstanceMethods
     
      def column_value_with_wf(column, issue, value)
        case column.name
          when :sub_category_id
            return issue.sub_category ? issue.sub_category.name : nil
          else
            return column_value_without_wf column, issue, value
        end
      end
    end
  end

end
