module Iox
  class ProgramEntryPerson < ActiveRecord::Base
    belongs_to :program_entry, touch: true
    belongs_to :person

    before_save :update_timestamps

    def as_json(options = { })
      h = super(options)
      h[:avatar_link] = person.avatar.url(:thumb)
      h[:person] = person
      h[:name] = person.name
      h[:person_function] = function
      h[:person_role] = role
      h
    end

    private

    def update_timestamps
      self.created_at = Time.now if new_record?
      self.updated_at = Time.now
    end

  end

end
