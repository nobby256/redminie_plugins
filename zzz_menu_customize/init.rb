Redmine::Plugin.register :zzz_menu_customize do
  name 'Zzz Menu Customize plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'

  Redmine::MenuManager.map :project_menu do |menu|
    menu.delete :roadmap
    menu.delete :overview
    menu.delete :activity
    
#    menu.push :zzz_menu_customize, { :controller => 'parking_lot_chart', :action => 'index' }, :parent => :gantt
    menu.delete :version_burndown_charts
    menu.push :version_burndown_charts, { :controller => 'version_burndown_charts', :action => 'index' }, :caption => :version_burndown_charts, :param => :project_id, :after => :parking_lot_chart
    menu.delete :gantt
    menu.push :gantt, { :controller => 'gantts', :action => 'show' }, :param => :project_id, :caption => :label_gantt, :after => :parking_lot_chart
  end
end
