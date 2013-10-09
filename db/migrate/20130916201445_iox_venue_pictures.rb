class IoxVenuePictures < ActiveRecord::Migration
  def change
    create_table :iox_venue_pictures do |t|

      t.attachment  :file
      t.string      :name
      t.string      :description
      t.string      :copyright
      t.integer     :position, default: 0

      t.belongs_to  :venue

      t.string      :import_file_url
      t.string      :import_foreign_db_name

      t.timestamps

    end
  end
end
