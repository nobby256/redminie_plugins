class CreateIssueSubCategories < ActiveRecord::Migration
  def self.up
    create_table :issue_sub_categories do |t|
      t.integer :project_id, :default => 0, :null => false
      t.string :name, :limit => 30, :default => "", :null => false
      t.integer :position, :default => 1
    end
    add_index "issue_sub_categories", ["project_id"], :name => "issue_sub_categories_project_id"
  end
end
