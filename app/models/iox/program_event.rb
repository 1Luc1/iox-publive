module Iox
  class ProgramEvent < ActiveRecord::Base

    belongs_to :program_entry, class_name: 'Iox::ProgramEntry', touch: true
    belongs_to :venue, class_name: 'Iox::Venue'
    belongs_to :festival, class_name: 'Iox::ProgramEntry', foreign_key: :festival_id

    belongs_to  :creator, class_name: 'Iox::User', foreign_key: 'created_by'
    belongs_to  :updater, class_name: 'Iox::User', foreign_key: 'updated_by'

    has_many :program_entry_events, dependent: :delete_all

    attr_accessor :starts_at_time, :ends_at_time, :reductions_arr

    before_save :update_start_end_time

    validate :starts_at, presence: true
    validate :venue_id, presence: true

    def price_from=(val)
      super( val.sub(',','.') )
    end

    def price_to=(val)
      super( val.sub(',','.') )
    end

    def as_json(options = { })
      h = super(options)
      h[:venue_name] = venue ? venue.name : ''
      h[:program_entry] = program_entry
      h[:festival_name] = festival ? festival.title : ''
      h[:reductions] = reductions ? reductions.split(',') : ''
      h[:updater_name] = updater ? updater.full_name : ( creator ? creator.full_name : ( import_foreign_db_name.blank? ? '' : import_foreign_db_name ) )
      h[:show_tickets] = !tickets_url.blank? || !tickets_other.blank? || !tickets_phone.blank?
      h
    end

    private

    def update_start_end_time
      if new_record? && ends_at.blank? && program_entry && program_entry.duration && program_entry.duration > 0
        self.ends_at = starts_at+(program_entry.duration.minutes || 0)
      end
    end

  end
end