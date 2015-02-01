class IssueSubCategory < ActiveRecord::Base
  include Redmine::SafeAttributes
  belongs_to :project
  has_many :issues, :foreign_key => 'sub_category_id', :dependent => :nullify

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:project_id]
  validates_length_of :name, :maximum => 30

  safe_attributes 'name', 'position'

  scope :named, lambda {|arg| where("LOWER(#{table_name}.name) = LOWER(?)", arg.to_s.strip)}

  def <=>(sub_category)
    name <=> sub_category.name
  end

  def to_s; name end
end
