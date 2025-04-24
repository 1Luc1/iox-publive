class CreateIoxInstagramPosts < ActiveRecord::Migration[5.2]
  def change
    create_table :iox_instagram_posts do |t|
      t.integer     :program_entry_id, null: false, index: { unique: true }
      t.integer     :program_event_id, null: false
      t.string      :ig_container_id
      t.string      :ig_media_id
      t.string      :shortcode
      t.integer     :status, default: 0

      t.timestamps
    end
  end
end
