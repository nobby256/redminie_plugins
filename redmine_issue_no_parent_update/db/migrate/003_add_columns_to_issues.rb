class AddColumnsToIssues < ActiveRecord::Migration

  def self.up
    add_column :issues, :tag, :string
    add_column :issues, :sub_category_id, :int
    add_column :issues, :list_order, :int
  end

  def self.down
    remove_column :issues, :tag
    remove_column :issues, :sub_category_id
    remove_columnn :issues, :list_order
  end

end