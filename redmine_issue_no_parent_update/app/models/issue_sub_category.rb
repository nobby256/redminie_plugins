class IssueSubCategory < ActiveRecord::Base
  include Redmine::SafeAttributes
  belongs_to :project
  has_many :issues, :foreign_key => 'sub_category_id', :dependent => :nullify

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:project_id]
  validates_length_of :name, :maximum => 30

  safe_attributes 'name', 'position'

  scope :named, lambda {|arg| where("LOWER(#{table_name}.name) = LOWER(?)", arg.to_s.strip)}

  alias :destroy_without_reassign :destroy

  # Destroy the category
  # If a sub category is specified, issues are reassigned to this sub category
  def destroy(reassign_to = nil)
    if reassign_to && reassign_to.is_a?(IssueSubCategory) && reassign_to.project == self.project
      Issue.where({:sub_category_id => id}).update_all({:sub_category_id => reassign_to.id})
    end
    destroy_without_reassign
  end

  def <=>(sub_category)
    name <=> sub_category.name
  end

  def to_s; name end
end
