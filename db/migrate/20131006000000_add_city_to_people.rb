class AddCityToPeople < ActiveRecord::Migration
  def change
    add_column :iox_people, :city, :string
    add_column :iox_people, :zip, :string
    add_column :iox_people, :gkz, :integer
    add_column :iox_people, :country, :string
  end
end