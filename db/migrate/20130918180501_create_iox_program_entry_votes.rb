class CreateIoxProgramEntryVotes < ActiveRecord::Migration
  def change
    create_table :iox_program_entry_votes do |t|

      t.string :ip_addr
      t.string :user_agent
      t.string :os

      t.integer :stars, required: true

      t.belongs_to :program_entry

      t.timestamps
    end
  end
end
