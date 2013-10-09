class AddLastNotifiedEnsembleIdToProgramEntries < ActiveRecord::Migration
  def change
    add_column :iox_program_entries, :last_notified_ensemble_ids, :text
    add_column :iox_program_entries, :last_notified_venue_ids, :text
    add_column :iox_program_entries, :last_notified_people_ids, :text
  end
end