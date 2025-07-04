# encoding: utf-8

module Iox
  class ProgramEntry < ActiveRecord::Base

    acts_as_iox_document

    attr_accessor :venue_id, :venue_name, :ensemble_name, :tmp_cab_artist, :tmp_author, :is_festival

    default_scope { where( deleted_at: nil ) }

    belongs_to  :ensemble
    belongs_to  :organizer, class_name: 'Iox::Ensemble', foreign_key: 'organizer_id'
    belongs_to  :creator, class_name: 'Iox::User', foreign_key: 'created_by'
    belongs_to  :updater, class_name: 'Iox::User', foreign_key: 'updated_by'
    has_one     :instagram_post, class_name: 'Iox::InstagramPost'
    has_many    :program_entry_people, -> { order(:position) }, dependent: :delete_all
    has_many    :program_entry_events, dependent: :delete_all
    has_many    :crew, through: :program_entry_people, source: :person
    has_many    :events, -> { order(:starts_at) }, class_name: 'Iox::ProgramEvent', dependent: :delete_all
    has_many    :festival_events, -> { order(:starts_at) }, foreign_key: :festival_id, class_name: 'Iox::ProgramEvent', dependent: :delete_all
    has_many    :images, -> { order(:position) }, class_name: 'Iox::ProgramFile', dependent: :destroy
    has_many    :venues, through: :events

    validates   :title, presence: true, length: { in: 2..255 }
    validates   :subtitle, length: { maximum: 255 }
    validates   :meta_keywords, length: { maximum: 255 }
    validates   :age, inclusion: { in: 1..20 }, numericality: true, allow_blank: true
    validates   :duration, inclusion: { in: 1..960 }, numericality: true, allow_blank: true

    has_many :stats, class_name: 'Iox::ProgramEntryStat', dependent: :delete_all
    has_many :votes, class_name: 'Iox::ProgramEntryVote', dependent: :delete_all

    before_save :cleanup_youtube_url
    after_save :update_people_links
    after_save :notify_owner_by_email

    def votes_total
      total = 0
      votes.each do |vote|
        total += vote.stars
      end
      total
    end

    def votes_mean
      total = votes_total
      total > 0 ? (total * 1.0 / votes.count) : 0
    end

    def conflicting_item
      return unless conflict_id
      self.class.where(id: conflict_id).first
    end

    def venue_names
      v = ''
      if events.size > 0 and events.first.venue
        v << "<a href='/iox/venues/#{events.first.venue.id}'>#{events.first.venue.name}/edit</a>"
      end
      v
    end

    def cabaret_artist_ids
      program_entry_people.where( function: 'Künstler').map{ |a| a.person_id }.join(',')
    end

    def cabaret_artist_ids=(artist_ids)
      self.tmp_cab_artist = artist_ids
    end

    def cabaret_artist_names
      program_entry_people.where( function: 'Künstler').map{ |a| a.person.name unless a.person.nil? }.join(',')
    end

    def author_ids
      program_entry_people.where( "function='Autor' OR function='Autorin'" ).map{ |a| a.person_id }.join(',')
    end

    def author_ids=(artist_ids)
      self.tmp_author = artist_ids
    end

    def authors
      program_entry_people.where( "function='Autor' OR function='Autorin'" ).map{ |a| a.person.full_name }
    end

    def to_param
      [id, title.parameterize].join("-")
    end

    def as_json(options = { })
      h = super(options)
      h[:name] = title
      if !options.key?(:simple)
        h[:venue_id] = venue_id
        h[:venue_name] = venue_name
        h[:cabaret_artist_names] = cabaret_artist_names
        h[:url] = to_param
        if events.first.nil?
          h[:tickets_url] = ''
        else
          h[:tickets_url] = events.first.tickets_url
        end
        if image = images.first
          h[:orig_url] = image.file.url(:original)
          h[:thumb_url] = image.file.url(:thumb)
          h[:thumb_title] = image.description.blank? && image.copyright.blank? ? '' : "#{image.description} ©#{image.copyright}"
        end
        h[:votes_mean] = votes_mean
        h[:votes_count] = votes.count
        h[:ensemble_name] = ensemble ? ensemble.name : ''
        h[:updater_name] = updater ? updater.full_name : ( creator ? creator.full_name : ( import_foreign_db_name.blank? ? '' : import_foreign_db_name ) )
      end
        h
    end

    def next_event_date
      if events.empty? 
        return Date.current.to_date
      end
      
      event = events.where('starts_at > ?', Date.current).first

      if event.nil?
        event = events.reorder(starts_at: :desc).first
      end

      return "#{event.starts_at.beginning_of_month.to_date}##{event.starts_at.to_date}"
    end

    def next_event_dates(e)
      events.where("starts_at >= ?", e.starts_at).where('iox_program_events.id <> ?', e.id).order(:starts_at)
    end

    private

    def update_people_links
      unless tmp_cab_artist.blank?
        tmp_cab_artist.split(',').each do |artist_id|
          unless program_entry_people.where( function: 'Künstler', person_id: artist_id ).first
            program_entry_people.create( person_id: artist_id, function: 'Künstler' )
          end
        end
      end
      unless tmp_author.blank?
        tmp_author.split(',').each do |artist_id|
          unless program_entry_people.where( "(function='Autor' OR function='Autorin') AND person_id=#{artist_id}" ).first
            program_entry_people.create( person_id: artist_id, function: 'Autor' )
          end
        end
      end
    end

    def cleanup_youtube_url
      return if youtube_url.blank?
      self.youtube_url = youtube_url.split('&')[0] if youtube_url.split('&').size > 1
    end

    def notify_owner_by_email

      if updated_by != created_by && updater && creator && notify_me_on_change
        Iox::PubliveMailer.content_changed( self, changes ).deliver
      end

    end

  end
end
