class AddArchivedToVenues < ActiveRecord::Migration
  def change
    add_column :iox_venues, :archived, :boolean, default: false
    add_column :iox_ensembles, :archived, :boolean, default: false
  end
end