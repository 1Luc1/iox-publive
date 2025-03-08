class AddShowInMagazinToProgramEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :iox_program_events, :show_in_magazin, :boolean
  end
end
