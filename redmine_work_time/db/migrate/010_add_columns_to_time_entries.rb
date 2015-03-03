class AddColumnsToTimeEntries < ActiveRecord::Migration

  def self.up
    add_column :time_entries, :done_ratio, :int
    add_column :time_entries, :status_id, :int
  end

  def self.down
    remove_column :time_entries, :done_ratio
    remove_column :time_entries, :status_id
  end

end