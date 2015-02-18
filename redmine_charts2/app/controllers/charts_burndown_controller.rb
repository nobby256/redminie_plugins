# coding: utf-8
class ChartsBurndownController < ChartsBurndownBaseController

  unloadable

  protected

  def get_data
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
    (RedmineCharts::ConditionsUtils.types - [:activity_ids, :user_ids]).flatten
  end

end
