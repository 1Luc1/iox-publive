class CreateIoxProgramEntryStats < ActiveRecord::Migration
  def change
    create_table :iox_program_entry_stats do |t|

      t.string :ip_addr
      t.string :user_agent
      t.string :os

      t.integer :views, default: 1
      t.integer :visits, default: 1

      t.string :lang

      t.belongs_to :program_entry

      t.date :day, index: true

      t.boolean         :others_can_change, default: true
      t.boolean         :notify_me_on_change, default: true

      t.timestamps
    end
  end
end
