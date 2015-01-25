require 'redmine'

Redmine::Plugin.register :redmine_version_burndown2 do
  name 'Redmine Version Burndown Charts plugin2'
  author 'Nobby256'
  description 'Version Burndown Charts Plugin is graphical chart plugin for Scrum.'

  requires_redmine :version_or_higher => '2.3.0'
  version '0.0.1'

  project_module :version_burndown_charts do
    permission :version_burndown_charts_view, :version_burndown_charts => :index
  end

  menu :project_menu, :version_burndown_charts, { :controller => 'version_burndown_charts', :action => 'index' },
  :caption => :version_burndown_charts, :after => :activity, :param => :project_id
end
