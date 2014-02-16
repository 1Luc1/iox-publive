class CreateIoxEnsembles < ActiveRecord::Migration
  def change
    create_table :iox_ensembles do |t|

      t.boolean         :organizer, default: false
      t.string          :name, index: true
      t.string          :street
      t.string          :city
      t.string          :zip
      t.integer         :gkz
      t.string          :country

      t.text            :description
      t.string          :meta_keywords

      t.string          :url
      t.string          :email
      t.string          :phone
      t.string          :tickets_url

      t.string          :facebook_url
      t.string          :twitter_url
      t.string          :youtube_url
      t.string          :google_plus_url

      t.float           :lat
      t.float           :lng

      t.integer         :forward_ensemble_id

      t.integer         :created_by
      t.integer         :updated_by

      t.integer         :import_foreign_db_id
      t.string          :import_foreign_db_name

      t.boolean         :others_can_change, default: true
      t.boolean         :notify_me_on_change, default: true

      t.integer         :conflicting_with_id

      t.timestamps
    end
  end
end
