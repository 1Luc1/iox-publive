module Iox
  class ProgramEntryStat < ActiveRecord::Base

    belongs_to :program_entry, inverse_of: :stats

  end
end
