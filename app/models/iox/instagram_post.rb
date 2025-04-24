module Iox
  class InstagramPost < ActiveRecord::Base
    belongs_to :program_entry, class_name: 'Iox::ProgramEntry', foreign_key: 'program_entry_id'
    belongs_to :program_event, class_name: 'Iox::ProgramEvent', foreign_key: 'program_event_id'
  end
end
