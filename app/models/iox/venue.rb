module Iox
  class Venue < ActiveRecord::Base

    acts_as_iox_document
    include Iox::FileObject

    default_scope { where( deleted_at: nil ) }

    has_many :program_events, dependent: :nullify
    has_many :events, class_name: 'Iox::ProgramEvent'

    belongs_to :creator, class_name: 'Iox::User', foreign_key: 'created_by'
    belongs_to  :updater, class_name: 'Iox::User', foreign_key: 'updated_by'

    has_many    :images, -> { order(:position) }, class_name: 'Iox::VenuePicture', dependent: :destroy

    validates :name, presence: true, uniqueness: true, if: :should_validate?

    before_save :set_default_country,
                :convert_zip_gkz

    # after_save :notify_owner_by_email

    def should_validate?
      !deleted_at.present? && !conflicting_with_id.present?
    end

    def program_entries(query='')
      pentries = []
      pentry_ids = []
      events.where(query).each do |e|
        next if pentry_ids.include? e.program_entry_id
        pentries << e.program_entry
        pentry_ids << e.program_entry_id
      end
      pentries #pentries.sort{ |a,b| false if( ! a.starts_at && !(a.starts_at && a.starts_at) <=> ( b.starts_at && b.starts_at ) }
    end

    def ensembles(query='')
      ensembles = []
      ensemble_ids = []
      events.where(query).each do |e|
        next unless e.program_entry
        next if ensemble_ids.include? e.program_entry.ensemble_id
        ensembles << e.program_entry.ensemble if e.program_entry.ensemble
        ensemble_ids << e.program_entry.ensemble_id
      end
      ensembles.sort{ |a,b| a.name <=> b.name }
    end


    def to_param
      [id, name.parameterize].join("-")
    end

    def as_json(options = { })
      h = super(options)
      if !options.key?(:simple)
        h[:events_num] = events.count
        h[:updater_name] = updater ? updater.full_name : (creator ? creator.full_name : ( import_foreign_db_name ? import_foreign_db_name : '' ))
      end
      h
    end

    private

    def notify_owner_by_email
      if updater && creator && updater.id != creator.id && notify_me_on_change
        Iox::PubliveMailer.content_changed( self, changes ).deliver
      end
    end

    # set default country if no country was given
    def set_default_country
      return unless country.blank?
      self.country = Rails.configuration.iox.default_country
    end

    def convert_zip_gkz
      return if zip.blank?
      if conversion = Iox::TspGkzZipConversion.where( "zip >= ?", zip ).limit(1).order(:zip).first
        self.gkz = conversion.gkz
        if conversion.zip != zip
          Iox::TspGkzZipConversion.create zip: zip, gkz: conversion.gkz
        end
      else
        puts "venue failed to find conversion for #{zip} #{city} #{name}"
      end
    end

  end

end
