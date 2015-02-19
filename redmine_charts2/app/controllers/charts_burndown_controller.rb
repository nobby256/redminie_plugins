# coding: utf-8
class ChartsBurndownController < ChartsBurndownBaseController

  unloadable

  protected

  def get_data
    @conditions[:fixed_version_ids] ||= get_fixed_version_ids(@project)
    if @conditions[:fixed_version_ids].empty?
      return { :error => :charts_error_no_version }
    end

    return get_data_core
  end

  def get_title
    l(:charts_link_burndown)
  end

  def show_date_condition
    true
  end

  def get_conditions_options
    []
  end

  def get_multiconditions_options
#    (RedmineCharts::ConditionsUtils.types - [:activity_ids, :user_ids]).flatten
    [:fixed_version_ids, :issue_ids, :user_ids, :category_ids, :tracker_ids, :assigned_to_ids ]
  end

end
