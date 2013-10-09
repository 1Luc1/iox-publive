module Iox
  class ProgramEntryEvent < ActiveRecord::Base
    belongs_to :entry, class_name: 'Iox::ProgramEntry', foreign_key: 'program_entry_id' # == festival
    belongs_to :festival, class_name: 'Iox::ProgramEntry', foreign_key: 'program_entry_id'
    belongs_to :event, class_name: 'Iox::ProgramEvent', foreign_key: 'program_event_id'
  end
end
