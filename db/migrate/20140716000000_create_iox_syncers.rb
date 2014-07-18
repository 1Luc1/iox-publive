class CreateIoxSyncers < ActiveRecord::Migration
  def change
    create_table :iox_syncers do |t|
      t.string      :name
      t.string      :url
      t.string      :cron_line
      t.integer     :festival_id
      t.integer     :user_id
      t.timestamps
    end

    create_table :iox_sync_logs do |t|
      t.string      :message
      t.integer     :ok
      t.integer     :failed
      t.integer     :syncer_id
      t.timestamps
    end
  end
end
