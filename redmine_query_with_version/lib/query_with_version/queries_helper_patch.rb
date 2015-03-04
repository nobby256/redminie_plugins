# coding: utf-8

require_dependency 'queries_helper'

module QueryWithVersion
  module QueriesHelperPatch
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
        unloadable

        alias_method_chain :retrieve_query, :version
      end
    end

    module InstanceMethods
      def retrieve_query_with_version
        retrieve_query_without_version

        if params[:query_id].present? and params[:fixed_version_id].present?
          add_filter_version_id = params[:fixed_version_id]

          session[:query][:fixed_version_id] = add_filter_version_id
        else
          if api_request? || params[:set_filter] || session[:query].nil? || session[:query][:project_id] != (@project ? @project.id : nil)
            if session[:query][:fixed_version_id]
              add_filter_version_id = session[:query][:fixed_version_id]
            end
          end
        end

        if add_filter_version_id.present?
          if add_filter_version_id == '0'
            @query.add_filter("fixed_version_id", '!*', [''])
            @querying_version = {:id => 0, :name => l(:label_none)}
          else
            @query.add_filter("fixed_version_id", "=", [add_filter_version_id])
            version = Version.find(add_filter_version_id)
            @querying_version = {:id => version.id, :name => version.name}
          end
        end
      end
     
    end
  end
end

unless QueriesHelper.included_modules.include?(QueryWithVersion::QueriesHelperPatch)
  QueriesHelper.send(:include, QueryWithVersion::QueriesHelperPatch)
end
