class AddUpdatedByToEnsemblePeople < ActiveRecord::Migration
  def change
    add_column :iox_ensemble_people, :updated_by, :string
  end
end