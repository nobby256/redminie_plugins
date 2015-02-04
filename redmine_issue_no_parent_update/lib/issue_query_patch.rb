require_dependency 'issue'

module IssueNoParentUpdate
  module IssueQueryPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :joins_for_order_statement, :wf
        alias_method_chain :initialize_available_filters, :wf

        self.available_columns.find do |query_column|
          query_column.sortable = "#{IssueCategory.table_name}.id" if query_column.name== :category
        end

        base.add_available_column(QueryColumn.new(:tag, sortable: "#{Issue.table_name}.tag", groupable: true, caption: :field_tag))
        base.add_available_column(QueryColumn.new(:sub_category_id, sortable: "#{IssueSubCategory.table_name}.position", groupable: true, caption: :field_sub_category))
        base.add_available_column(QueryColumn.new(:external_order, sortable: "#{Issue.table_name}.external_order", groupable: false, caption: :field_external_order))
      end
    end

    module InstanceMethods
=begin
      def sql_for_tag_field(field, operator, value)
        return sql_for_field(field, operator, value, Issue.table_name, 'tag', false)
      end

      def sql_for_sub_category_id_field(field, operator, value)
        return sql_for_field(field, operator, value, Issue.table_name, 'sub_category_id', false)
      end
=end
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