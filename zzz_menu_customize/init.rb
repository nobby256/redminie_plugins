Redmine::Plugin.register :zzz_menu_customize do
  name 'Zzz Menu Customize plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'

  Redmine::MenuManager.map :project_menu do |menu|
    menu.delete :roadmap
#    menu.delete :work_time
    
#    menu.push :zzz_menu_customize, { :controller => 'parking_lot_chart', :action => 'index' }, :parent => :gantt
  end

end
