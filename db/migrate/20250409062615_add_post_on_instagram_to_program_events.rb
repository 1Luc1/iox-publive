class AddPostOnInstagramToProgramEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :iox_program_events, :post_on_instagram, :boolean
  end
end
