class CreateIssueSubCategories < ActiveRecord::Migration
  def self.up
    create_table :issue_sub_categories do |t|
      t.integer :project_id, :null => false
      t.string :name, :null => false
      t.integer :position, :null => false
    end
  end
end
