class AddColumnsToVersions < ActiveRecord::Migration

  def self.up
    execute <<-SQL
create view chart_view_timelines as
select
    cast(spent_on as date) as spent_on
  , cast((tyear * 1000) + dayofyear(spent_on) as signed) as day
  , cast((tyear * 1000) + tweek - 1 as signed) as week
  , cast((tyear * 1000) + tmonth  as signed) as month
  , cast(sum(hours)  as signed) as logged_hours
  , cast(count(*)  as signed) as entries
  , user_id
  , issue_id
  , activity_id
  , project_id 
from
  time_entries 
where
  hours > 0
group by
  project_id
  , user_id
  , issue_id
  , activity_id
  , spent_on
    SQL

    execute <<-SQL
create view chart_view_aggregated_timelines as
select
   cast(null as date) as spent_on
  , cast(0 as signed) as day
  , cast(0 as signed) as week
  , cast(0 as signed) as month
  , cast(sum(hours) as signed) as logged_hours
  , cast(count(*) as signed) as entries
  , user_id
  , issue_id
  , activity_id
  , project_id 
from
  time_entries 
group by
  project_id
  , user_id
  , issue_id
  , activity_id
order by
  project_id
  , issue_id
  , spent_on
  , user_id
  , activity_id
    SQL

    execute <<-SQL
create view chart_view_done_ratios as
select
  cast(spent_on as date) as spent_on
  , cast((tyear * 1000) + dayofyear(spent_on) as signed) as day
  , cast((tyear * 1000) + tweek - 1 as signed) as week
  , cast((tyear * 1000) + tmonth as signed) as month
  , project_id
  , issue_id
  , done_ratio 
from
  time_entries as t1 
where
  done_ratio is not null 
  and not exists ( 
    select
      * 
    from
      time_entries t2 
    where
      t1.project_id = t2.project_id 
      and t1.issue_id = t2.issue_id 
      and t1.spent_on = t2.spent_on 
      and t1.id < t2.id 
      and t2.done_ratio is not null 
  ) 
    SQL

    execute <<-SQL
create view chart_view_aggregated_done_ratios as
select
  cast(null as date) as spent_on
  , cast(0 as signed) as day
  , cast(0 as signed) as week
  , cast(0 as signed) as month
  , project_id
  , issue_id
  , done_ratio 
from
  time_entries as t1 
where
  done_ratio is not null 
  and not exists ( 
    select
      * 
    from
      time_entries t2 
    where
      t1.project_id = t2.project_id 
      and t1.issue_id = t2.issue_id 
      and t1.id < t2.id 
      and t2.done_ratio is not null 
  )
    SQL

    execute <<-SQL
select
  cast(spent_on as date) as spent_on
  , cast((tyear * 1000) + dayofyear(spent_on) as signed) as day
  , cast((tyear * 1000) + tweek - 1 as signed) as week
  , cast((tyear * 1000) + tmonth as signed) as month
  , project_id
  , issue_id
  , status_id 
from
  time_entries as t1 
where
  status_id is not null 
  and not exists ( 
    select
      * 
    from
      time_entries t2 
    where
      t1.project_id = t2.project_id 
      and t1.issue_id = t2.issue_id 
      and t1.spent_on = t2.spent_on 
      and t1.id < t2.id 
      and t2.status_id is not null 
  ) 
    SQL

  end

  def self.down
    execute <<-SQL
drop view if exists chart_view_timelines
    SQL
    execute <<-SQL
drop view if exists chart_view_aggregated_timelines
    SQL
    execute <<-SQL
drop view if exists chart_view_done_ratios
    SQL
    execute <<-SQL
drop view if exists chart_view_aggregated_done_ratios
    SQL
    execute <<-SQL
drop view if exists chart_view_statuses
    SQL
  end

end