class CreateIoxSettings < ActiveRecord::Migration[5.2]
  def self.up
    create_table :iox_settings do |t|
      t.string  :var,        null: false
      t.text    :value,      null: true
      t.timestamps
    end

    add_index :iox_settings, %i(var), unique: true
  end

  def self.down
    drop_table :iox_settings
  end
end
