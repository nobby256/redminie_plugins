class AddColumnsToVersions < ActiveRecord::Migration

  def self.up
    add_column :versions, :range_start_date, :date, :null => true
  end

  def self.down
    remove_column :versions, :range_start_date
  end

end