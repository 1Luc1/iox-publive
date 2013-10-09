class CreateIoxProgramEntryPeople < ActiveRecord::Migration
  def change
    create_table :iox_program_entry_people do |t|

      t.integer     :program_entry_id
      t.integer     :person_id

      t.string      :function
      t.integer     :position

      t.integer     :created_by
      t.integer     :updated_by
      t.timestamps

    end
  end
end
