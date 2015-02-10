require_dependency 'issue'

module IssueNoParentUpdate
  module IssueQueryPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :joins_for_order_statement, :wf
        alias_method_chain :initialize_available_filters, :wf
        alias_method_chain :issues, :wf

        self.available_columns.find do |query_column|
          query_column.sortable = "#{IssueCategory.table_name}.id" if query_column.name== :category
        end

        base.add_available_column(QueryColumn.new(:tag, sortable: "#{Issue.table_name}.tag", groupable: true, caption: :field_tag))
        base.add_available_column(QueryColumn.new(:sub_category, sortable: "#{IssueSubCategory.table_name}.position", groupable: true, caption: :field_sub_category))
        base.add_available_column(QueryColumn.new(:external_order, sortable: "#{Issue.table_name}.external_order", groupable: false, caption: :field_external_order))
        base.add_available_column(QueryColumn.new(:started_on,
                                                  :sortable => "COALESCE((SELECT MIN(created_on) FROM #{TimeEntry.table_name} WHERE #{TimeEntry.table_name}.issue_id = #{Issue.table_name}.id), 0)",
                                                  :default_order => 'asc',
                                                  :caption => :label_started_on
                                                  ))
      end
    end

    module InstanceMethods

      def issues_with_wf(options={})
        issues = issues_without_wf(options)

        if has_column?(:started_on)
          Issue.load_visible_started_on(issues)
        end
=begin
        if has_column?(:closed_on)
          issues.each do |issue|
            closed_on_value = issue.closed_on
            if closed_on_value
              issue.closed_on = Date.new(closed_on_value.year, closed_on_value.month, closed_on_value.day)
            end
          end
        end
=end
        return issues
      rescue ::ActiveRecord::StatementInvalid => e
        raise StatementInvalid.new(e.message)
      end

      def issue_count_by_group_with_wf
        if (group_by_statement == 'tag')
          gr_b = "case when #{IssueStatus.table_name}.is_closed = #{connection.quoted_false} and uis_ir.id is null then 1 else 0 end"
          return Issue.visible.joins(:status, :project).where(statement).joins(joins_for_order_statement(gr_b)).group(gr_b).count
        elsif (group_by_statement == 'sub_category')
          gr_b = "case when #{IssueStatus.table_name}.is_closed = #{connection.quoted_false} and uis_ir.read_date < #{Issue.table_name}.updated_on then 1 else 0 end"
          return Issue.visible.joins(:status, :project).where(statement).joins(joins_for_order_statement(gr_b)).group(gr_b).count
        end

        return issue_count_by_group_without_wf
      end

      def initialize_available_filters_with_wf
        initialize_available_filters_without_wf( )

        add_available_filter 'tag', :type => :text

        sub_categories = []
        if project
          sub_categories = project.issue_sub_categories.all
        end
        add_available_filter 'sub_category_id',
          :type => :list_optional,
          :values => sub_categories.collect{|s| [s.name, s.id.to_s] }
      end

      def joins_for_order_statement_with_wf(order_options)
        joins = joins_for_order_statement_without_wf(order_options)
        joins ||= ''
        if order_options
          if order_options.include?(IssueSubCategory.table_name)
            joins << " LEFT OUTER JOIN #{IssueSubCategory.table_name} ON #{IssueSubCategory.table_name}.id = #{Issue.table_name}.sub_category_id"
          end
        end
        return joins
      end

    end
  end
end