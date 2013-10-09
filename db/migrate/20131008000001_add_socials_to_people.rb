class AddSocialsToPeople < ActiveRecord::Migration
  def change
    add_column :iox_people, :facebook_url, :string
    add_column :iox_people, :youtube_url, :string
    add_column :iox_people, :twitter_url, :string
    add_column :iox_people, :google_plus_url, :string
    add_column :iox_people, :phone, :string
  end
end