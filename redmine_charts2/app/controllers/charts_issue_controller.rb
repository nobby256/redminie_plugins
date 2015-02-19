class ChartsIssueController < ChartsController

  unloadable
  
  protected

  def get_data
    @grouping ||= :status_id
    @conditions[:fixed_version_ids] ||= get_fixed_version_ids(@project)
    if @conditions[:fixed_version_ids].empty?
      return { :error => :charts_error_no_version }
    end

    conditions = {}

    @conditions.each do |c, v|
      column_name = RedmineCharts::ConditionsUtils.to_column(c, 'issues')
      conditions[column_name] = v if v and column_name
    end

    group_column = RedmineCharts::GroupingUtils.to_column(@grouping, 'issues')

    rows = Issue.all(:select => "#{group_column || 0} as group_id, count(*) as issues_count", :conditions => conditions, :group => group_column)

    total_issues = 0

    rows.each do |row|
      total_issues += row.issues_count.to_i
    end

    labels = []
    set = []
    error = nil

    if rows.empty?
      error = :charts_error_no_data
    else
      rows.each do |row|
        labels << l(:charts_issue_label, { :label => RedmineCharts::GroupingUtils.to_string(row.group_id, @grouping, l(:charts_issue_others)) })
        hint = l(:charts_issue_hint, { :label => RedmineCharts::GroupingUtils.to_string(row.group_id, @grouping, l(:charts_issue_others)), :issues => row.issues_count, :percent => RedmineCharts::Utils.percent(row.issues_count, total_issues), :total_issues => total_issues })
        set << [row.issues_count.to_i, hint]
      end
    end

    {
      :error => error,
      :labels => labels,
      :count => rows.size,
      :max => 0,
      :sets => {"" => set}
    }
  end

  def get_title
    l(:charts_link_issue)
  end
  
  def get_help
    l(:charts_issue_help)
  end
  
  def get_type
    :pie
  end

  def get_grouping_options
#    (RedmineCharts::GroupingUtils.types - [:activity_id, :issue_id, :user_id]).flatten
    [ :category_id, :tracker_id, :fixed_version_id, :priority_id, :author_id, :status_id, :project_id, :assigned_to_id ]
  end

  def get_multiconditions_options
#    (RedmineCharts::ConditionsUtils.types - [:activity_ids, :issue_ids, :user_ids]).flatten
    [ :category_ids, :status_ids, :fixed_version_ids, :tracker_ids, :priority_ids, :author_ids, :assigned_to_ids ]
  end


end
