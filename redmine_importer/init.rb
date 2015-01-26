# encoding: UTF-8

require 'redmine'

Redmine::Plugin.register :redmine_importer do
  name 'Issue Importer'
  author 'Martin Liu / Leo Hourvitz / Stoyan Zhekov / Jérôme Bataille'
  description 'Issue import plugin for Redmine.'
  version '1.2.2'

  project_module :importer do
    permission :import, :importer => :index
  end
  #menu :project_menu, :importer, { :controller => 'importer', :action => 'index' }, :caption => :label_import, :before => :settings, :param => :project_id

  Rails.configuration.to_prepare do
    require_dependency 'projects_helper'
    unless ProjectsHelper.included_modules.include? IssueImportHelperPatch
      ProjectsHelper.send(:include, IssueImportHelperPatch)  
    end 
  end 
end
