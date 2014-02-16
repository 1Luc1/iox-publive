class CreateIoxVenues < ActiveRecord::Migration
  def change
    create_table :iox_venues do |t|

      t.string          :name, index: true
      t.text            :description
      t.string          :url
      t.string          :email
      t.string          :phone

      t.string          :tickets_url

      t.string          :country
      t.string          :city
      t.string          :zip
      t.integer         :gkz
      t.string          :street

      t.string          :facebook_url
      t.string          :twitter_url
      t.string          :youtube_url
      t.string          :google_plus_url

      t.string          :meta_keywords

      t.float           :lat
      t.float           :lng

      t.attachment      :logo

      t.integer         :created_by

      t.integer         :forward_venue_id

      t.boolean         :others_can_change, default: true
      t.boolean         :notify_me_on_change, default: true

      t.integer         :import_foreign_db_id
      t.string          :import_foreign_db_name

      t.integer         :conflicting_with_id

      t.timestamps
    end
  end
end
