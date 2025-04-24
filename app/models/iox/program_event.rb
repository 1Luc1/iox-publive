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

    validates :starts_at, presence: true
    validates :venue_id, presence: true

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
      h[:reductions] = reductions
      h[:updater_name] = updater ? updater.full_name : ( creator ? creator.full_name : ( import_foreign_db_name.blank? ? '' : import_foreign_db_name ) )
      h[:show_tickets] = !tickets_url.blank? || !tickets_other.blank? || !tickets_phone.blank?
      h
    end

    def valid_tickets_url()
      valid_url = tickets_url
      uri = URI.parse(valid_url.strip)
      if !%w( http https ).include?(uri.scheme)
        valid_url = "https://#{valid_url}"
      end
      return valid_url
    end

    # 'starts_at >' means premieres on the same date won't be posted
    # DateTime.now.beginning_of_day - 1.day we exclude dates which are on the current date
    # show every premiere starting tomorrow
    # get all program events which ... 
    # is a premiere
    # have checkbox post on instagram true
    # have at least one image
    # only one premiere (post) per program entry
    # arn't in the past and not one month away
    def self.postable_on_instagram
      joins(program_entry: :images).left_outer_joins(program_entry: :instagram_post)
        .where(post_on_instagram: true)
        .where('iox_program_events.starts_at > ?', DateTime.now.beginning_of_day + 1.day)
        .where(iox_program_entries: {published: true})
        .where.not(iox_program_files: { id: nil })
        .where(iox_instagram_posts: { id: nil }).distinct
    end

    def self.max_one_month
      where('iox_program_events.starts_at <= ?', DateTime.now + 1.month)
    end

    private

    def update_start_end_time
      if new_record? && ends_at.blank? && program_entry && program_entry.duration && program_entry.duration > 0
        self.ends_at = starts_at + (program_entry.duration && program_entry.duration.is_a?(Fixnum) ? program_entry.duration.minutes : 0)
      end
    end

  end
end
