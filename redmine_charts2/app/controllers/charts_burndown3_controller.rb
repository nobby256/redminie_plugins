# coding: utf-8
class ChartsBurndown3Controller < ChartsBurndownBaseController

  unloadable

  protected

  def get_data
    @conditions[:fixed_version_ids] ||= get_current_fixed_version_in(@project)
    version = unless @conditions[:fixed_version_ids].empty?
      Version.first(:conditions => {:id => @conditions[:fixed_version_ids][0]})
    end
    unless version
      return { :error => :charts_error_no_version }
    end

    end_date = version.effective_date ? version.effective_date.to_date : Time.now.to_date
    start_date = version.start_date ? version.start_date : end_date << 1 #開始日が無い場合は期日の１か月前をデフォルトの開始日とする
    @range = RedmineCharts::RangeUtils.propose_range_for_two_dates(start_date, end_date)
    
    return get_data_core
  end

  def get_title
    l(:charts_link_burndown3)
  end

  def show_date_condition
    false
  end

  def get_conditions_options
    [:fixed_version_ids]
  end

  def get_multiconditions_options
#    (RedmineCharts::ConditionsUtils.types - [:activity_ids, :user_ids, :fixed_version_ids, :project_ids]).flatten
    [ :issue_ids, :user_ids, :category_ids, :tracker_ids, :assigned_to_ids ]
  end

end
