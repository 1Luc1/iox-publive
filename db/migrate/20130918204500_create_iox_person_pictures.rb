class CreateIoxPersonPictures < ActiveRecord::Migration
  def change
    create_table :iox_person_pictures do |t|

      t.attachment  :file
      t.string      :name
      t.string      :description
      t.string      :copyright
      t.integer     :position, default: 0

      t.belongs_to  :person

      t.string      :import_file_url
      t.string      :import_foreign_db_name

      t.integer       :created_by
      t.integer       :updated_by

      t.timestamps

    end
  end
end
