module Iox
  class Syncer < ActiveRecord::Base
    
    belongs_to :user
    belongs_to :festival, class_name: 'Iox::ProgramEntry'
    has_many :sync_logs, -> { order 'created_at desc' }

    validate :legal_festival_id

    private

    def legal_festival_id
      return if self.festival_id.blank?
      return unless self.festival_id.is_a? Integer
      return if self.festival_id < 1
      return if ProgramEntry.find_by_id( self.festival_id )
      errors.add(:festival_id, "festival not found")
    end

  end
end
