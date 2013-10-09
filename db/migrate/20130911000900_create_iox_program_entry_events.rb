class CreateIoxProgramEntryEvents < ActiveRecord::Migration
  def change
    create_table :iox_program_entry_events do |t|

      t.integer     :program_entry_id
      t.integer     :program_event_id

      # CREATE TABLE iox_program_entry_events( program_event_id INTEGER, program_entry_id INTEGER );

    end
  end
end
