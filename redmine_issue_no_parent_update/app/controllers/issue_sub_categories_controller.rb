class IssueSubCategoriesController < ApplicationController
  menu_item :settings
  model_object IssueSubCategory
  before_filter :find_model_object, :except => [:index, :new, :create]
  before_filter :find_project_from_association, :except => [:index, :new, :create]
  before_filter :find_project_by_project_id, :only => [:index, :new, :create]
  before_filter :authorize
  accept_api_auth :index, :show, :create, :update, :destroy

  def index
    respond_to do |format|
      format.html { redirect_to_settings_in_projects }
      format.api { @sub_categories = @project.issue_sub_categories.all }
    end
  end

  def show
    respond_to do |format|
      format.html { redirect_to_settings_in_projects }
      format.api
    end
  end

  def new
    @sub_categories = @project.issue_sub_categories.build
    @sub_categories.safe_attributes = params[:issue_sub_category]

    respond_to do |format|
      format.html
      format.js
    end
  end

  def create
    @sub_category = @project.issue_sub_categories.build
    @sub_category.safe_attributes = params[:issue_sub_category]
    if @sub_category.save
      respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_successful_create)
          redirect_to_settings_in_projects
        end
        format.js
        format.api { render :action => 'show', :status => :created, :location => issue_sub_category_path(@sub_category) }
      end
    else
      respond_to do |format|
        format.html { render :action => 'new'}
        format.js   { render :action => 'new'}
        format.api { render_validation_errors(@sub_category) }
      end
    end
  end

  def edit
  end

  def update
    @sub_category.safe_attributes = params[:issue_sub_category]
    if @sub_category.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_to_settings_in_projects
        }
        format.api { render_api_ok }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
        format.api { render_validation_errors(@sub_category) }
      end
    end
  end

  def destroy
    @issue_count = @sub_category.issues.size
    if @issue_count == 0 || params[:todo] || api_request?
      reassign_to = nil
      if params[:reassign_to_id] && (params[:todo] == 'reassign' || params[:todo].blank?)
        reassign_to = @project.issue_sub_categories.find_by_id(params[:reassign_to_id])
      end
      @sub_category.destroy(reassign_to)
      respond_to do |format|
        format.html { redirect_to_settings_in_projects }
        format.api { render_api_ok }
      end
      return
    end
    @sub_categories = @project.issue_sub_categories - [@sub_category]
  end

  private

  def redirect_to_settings_in_projects
    redirect_to settings_project_path(@project, :tab => 'sub_categories')
  end

  # Wrap ApplicationController's find_model_object method to set
  # @category instead of just @issue_sub_category
  def find_model_object
    super
    @sub_category = @object
  end
end
