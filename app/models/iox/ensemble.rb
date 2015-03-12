module Iox

  class Ensemble < ActiveRecord::Base

    acts_as_iox_document

    default_scope { where( deleted_at: nil ) }

    has_many    :ensemble_people, dependent: :destroy
    has_many    :members, through: :ensemble_people, source: :person

    has_many    :program_entries
    belongs_to  :creator, class_name: 'Iox::User', foreign_key: 'created_by'
    belongs_to  :updater, class_name: 'Iox::User', foreign_key: 'updated_by'

    has_many    :images, -> { order(:position) }, class_name: 'Iox::EnsemblePicture', dependent: :destroy

    validates   :name, presence: true

    before_save :set_default_country,
                :convert_zip_gkz

    after_save :notify_owner_by_email

    def to_param
      [id, name.parameterize].join("-")
    end

    def as_json(options = { })
      h = super(options)
      h[:projects_num] = program_entries.count
      h[:members_num] = members.count
      h[:updater_name] = updater ? updater.full_name : (creator ? creator.full_name : ( import_foreign_db_name ? import_foreign_db_name : '' ))
      h
    end

    private

    # set default country if no country was given
    def set_default_country
      return unless country.blank?
      self.country = Rails.configuration.iox.default_country
    end

    def notify_owner_by_email
      if updater && creator && updater.id != creator.id && notify_me_on_change
        Iox::PubliveMailer.content_changed( self, changes ).deliver
      end
    end

    def convert_zip_gkz
      return if zip.blank?
      if conversion = Iox::TspGkzZipConversion.where( "zip >= ?", zip ).limit(1).order(:zip).first
        self.gkz = conversion.gkz
        if conversion.zip != zip
          Iox::TspGkzZipConversion.create zip: zip, gkz: conversion.gkz
        end
      else
        puts "ensemble failed to find conversion for #{zip} #{city} #{name}"
      end
    end

  end

end
