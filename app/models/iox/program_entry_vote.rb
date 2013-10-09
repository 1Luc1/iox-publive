module Iox
  class ProgramEntryVote < ActiveRecord::Base

    belongs_to :program_entry, inverse_of: :votes

    validates :stars, presence: true, inclusion: { in: 1..5 }, numericality: true

  end
end
