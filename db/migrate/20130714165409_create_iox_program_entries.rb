class CreateIoxProgramEntries < ActiveRecord::Migration
  def change
    create_table :iox_program_entries do |t|

      t.string          :title, index: true
      t.string          :subtitle

      t.boolean         :conflict, default: false
      t.integer         :conflict_id
      t.boolean         :review, default: false
      t.boolean         :completed, default: false
      t.date            :starts_at, index: true
      t.date            :ends_at, index: true

      t.text            :url

      t.text            :description

      t.text            :meta_keywords

      t.belongs_to      :ensemble
      t.integer         :organizer_id
      t.string          :coproduction

      t.string          :youtube_url
      t.string          :vimeo_url

      t.string          :categories, index: true

      t.integer         :duration
      t.boolean         :has_breaks
      t.integer         :age

      t.boolean         :published, default: false

      t.integer         :created_by
      t.integer         :updated_by

      t.integer         :import_foreign_db_id
      t.string          :import_foreign_db_name

      t.boolean         :show_cabaret_artists_in_title, default: true

      t.boolean         :others_can_change, default: true
      t.boolean         :notify_me_on_change, default: true

      t.timestamps
    end
  end
end
