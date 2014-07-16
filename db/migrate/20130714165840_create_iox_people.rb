class CreateIoxPeople < ActiveRecord::Migration
  def change
    create_table :iox_people do |t|

      t.string            :firstname
      t.string            :lastname
      t.string            :email
      t.string            :url
      t.string            :confirmation_key
      t.integer           :privacy_settings, index: true
      t.text              :description

      t.string            :meta_keywords

      t.attachment        :avatar

      t.integer           :created_by
      t.integer           :import_foreign_db_id, unique: true
      t.string            :import_foreign_db_name

      t.string          :sync_id
      t.string          :sync_name

      t.integer         :conflicting_with_id

      t.timestamps
    end
  end
end
