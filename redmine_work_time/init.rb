require 'redmine'

Redmine::Plugin.register :redmine_work_time do
  name 'Redmine Work Time plugin'
  author 'Tomohisa Kusukawa'
  description 'A plugin to view and update TimeEntry by each user'
  version '0.2.16'
  url 'http://www.r-labs.org/projects/worktime'
  author_url 'http://about.me/kusu'
  
  project_module :work_time do
    permission :view_work_time_tab, {:work_time =>
            [:show,:member_monthly_data,
            :total,:total_data,:edit_relay,:relay_total,:relay_total_data,
            ]}
    permission :view_work_time_other_member, {}
    permission :edit_work_time_total, {}
    permission :edit_work_time_other_member, {}
  end

  menu :account_menu, :work_time,
    {:controller => 'work_time', :action => 'index'}, :caption => :work_time
  menu :project_menu, :work_time,
    {:controller => 'work_time', :action => 'relay_total'}, :caption => :work_time
end
