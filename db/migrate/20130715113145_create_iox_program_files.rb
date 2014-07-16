class CreateIoxProgramFiles < ActiveRecord::Migration
  def change
    create_table :iox_program_files do |t|

      t.attachment  :file
      t.string      :name
      t.string      :description
      t.string      :copyright
      t.integer     :position, default: 0

      t.string      :orig_url

      t.belongs_to  :program_entry

      t.string      :import_file_url
      t.string      :import_foreign_db_name

      t.string      :sync_id
      t.string      :sync_name

      t.timestamps

    end
  end
end
