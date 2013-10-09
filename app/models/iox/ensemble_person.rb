module Iox
  class EnsemblePerson < ActiveRecord::Base
    belongs_to :ensemble
    belongs_to :person


    def as_json(options = { })
      h = super(options)
      h[:avatar_link] = person ? person.avatar.url(:thumb) : nil
      h[:person] = person
      h[:name] = person.name
      h[:person_function] = function
      h
    end


  end

end
