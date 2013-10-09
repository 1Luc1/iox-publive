class ChangePricesToFloatInProgramEvents < ActiveRecord::Migration
  def change
    change_column :iox_program_events, :price_from, :float
    change_column :iox_program_events, :price_to, :float
  end
end