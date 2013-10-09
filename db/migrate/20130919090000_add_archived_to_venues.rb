class AddArchivedToVenues < ActiveRecord::Migration
  def change
    add_column :iox_venues, :archived, :boolean
    add_column :iox_ensembles, :archived, :boolean
  end
end