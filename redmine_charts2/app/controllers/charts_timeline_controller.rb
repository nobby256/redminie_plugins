# coding: utf-8
class ChartsTimelineController < ChartsController

  unloadable
  
  protected

  def get_data
    @grouping ||= :activity_id

    @conditions[:fixed_version_ids] ||= get_fixed_version_ids(@project)
    if @conditions[:fixed_version_ids].empty?
      return { :error => :charts_error_no_version }
    end
    versions = Version.where("project_id=?", @project.id).all
    
    start_date = Time.now.to_date >> 1 #１ヶ月前をデフォルトとする
    versions.each do |version|
      if version.start_date
        if start_date > version.start_date
          start_date = version.start_date
        end
      end
    end
    end_date = nil
    versions.each do |version|
      if version.effective_date?
        end_date ||= version.effective_date
        if end_date < version.effective_date
          end_date = version.effective_date
        end
      end
    end
    unless end_date
      end_date = Time.now.to_date
    end
    
    @range = RedmineCharts::RangeUtils.propose_range_for_two_dates(start_date, end_date)

    rows, @range = ChartTimeEntry.get_timeline(@grouping, @conditions, @range)

    sets = {}
    max = 0

    
    if rows.size > 0
      rows.each do |row|
        group_name = RedmineCharts::GroupingUtils.to_string(row.group_id, @grouping)
        # Issue 13 
        val = row.range_value.to_s
        if (@range[:range] == :weeks) && (val =~ /000$/)
          val = RedmineCharts::RangeUtils.format_week(Date.new(val[0,4].to_i));
        end
        index = @range[:keys].index(val)
        if index
          sets[group_name] ||= Array.new(@range[:keys].size, [0, get_hints(group_name, nil)])
          sets[group_name][index] = [row.logged_hours.to_f, get_hints(group_name, row)]
          max = row.logged_hours.to_f if max < row.logged_hours.to_f
        else
          raise row.range_value.to_s
        end
      end
    else
      sets[""] ||= Array.new(@range[:keys].size, [0, get_hints(RedmineCharts::GroupingUtils.to_string(nil, @grouping), nil)])
    end

    sets = sets.sort.collect { |name, values| [name, values] }

    {
      :labels => @range[:labels],
      :count => @range[:keys].size,
      :max => max > 1 ? max : 1,
      :sets => sets
    }
  end

  def get_hints(group_name, record = nil)
    unless record.nil?
      l(:charts_timeline_hint, { :group_name => group_name, :hours => RedmineCharts::Utils.round(record.logged_hours), :entries => record.entries.to_i })
    else
      l(:charts_timeline_hint_empty, { :group_name => group_name} )
    end
  end

  def get_title
    l(:charts_link_timeline)
  end
  
  def get_help
    l(:charts_timeline_help)
  end

  def get_type
    :line
  end

  def get_x_legend
    l(:charts_timeline_x)
  end
  
  def get_y_legend
    l(:charts_timeline_y)
  end

  def show_date_condition
    false
  end

  def get_grouping_options
    [ :none, RedmineCharts::GroupingUtils.types ].flatten
  end

  def get_multiconditions_options
#    RedmineCharts::ConditionsUtils.types
    (RedmineCharts::ConditionsUtils.types - [:project_ids, :fixed_version_ids]).flatten
  end

end
