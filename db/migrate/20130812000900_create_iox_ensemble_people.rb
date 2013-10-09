class CreateIoxEnsemblePeople < ActiveRecord::Migration
  def change
    create_table :iox_ensemble_people do |t|

      t.integer     :ensemble_id
      t.integer     :person_id

      t.string      :function
      t.integer     :position
      t.date        :membership_start
      t.date        :membership_end

      t.integer     :created_by

    end
  end
end
