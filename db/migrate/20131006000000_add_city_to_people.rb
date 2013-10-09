class AddCityToPeople < ActiveRecord::Migration
  def change
    add_column :iox_people, :city, :string
    add_column :iox_people, :zip, :string
  end
end