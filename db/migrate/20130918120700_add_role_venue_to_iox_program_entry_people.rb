class AddRoleVenueToIoxProgramEntryPeople < ActiveRecord::Migration
  def change
    add_column :iox_program_entry_people, :role, :string
  end
end