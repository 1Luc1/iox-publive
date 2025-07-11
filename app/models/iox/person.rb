module Iox
  class Person < ActiveRecord::Base

    acts_as_iox_document

    include Iox::FileObject

    has_many :program_entry_people, dependent: :destroy
    has_many :program_entries, through: :program_entry_people

    has_many :ensemble_people
    has_many :ensembles, through: :ensemble_people

    has_many :taggings
    has_many :tags, through: :taggings

    belongs_to :creator, class_name: 'Iox::User', foreign_key: 'created_by'
    belongs_to  :updater, class_name: 'Iox::User', foreign_key: 'updated_by'

    # paperclip plugin
    has_attached_file :avatar,
                      :styles => Rails.configuration.iox.person_picture_sizes,
                      :default_url => "/images/iox/avatar/:style/missing.png",
                      :url => "/data/iox/person_avatars/:hash.:extension",
                      :hash_secret => "5b1b59b59b08dfef721470feed062327909b8f92"

    validates :lastname, presence: true, if: :should_validate?
    validates_uniqueness_of :lastname, scope: [:firstname], case_sensitive: false, conditions: -> { where(deleted_at: nil) }, if: :should_validate?
    validates :email, presence: true, if: :should_validate?

    after_save :notify_owner_by_email

    before_save :set_default_country,
                :convert_zip_gkz

    has_many    :images, -> { order(:position) }, class_name: 'Iox::PersonPicture', dependent: :destroy

    def name
      "#{firstname}#{" " if !firstname.blank? && !lastname.blank?}#{lastname}"
    end

    def should_validate?
      !deleted_at.present? && !conflicting_with_id.present? && !sync_id.present?
    end

    def get_functions_list
      funcs = []
      ProgramEntryPerson.where(person_id: id).uniq.pluck(:function).each do |func|
        func.split(',').each do |f|
          funcs << f unless funcs.include?(f)
        end
      end
      funcs
    end

    def name=(full_name)
      return if full_name.blank?
      if full_name.split(' ').size > 1
        self.firstname = full_name.split(' ')[0..-2].join(' ')
        self.lastname = full_name.split(' ')[-1]
      else
        self.lastname = full_name
      end
    end

    def to_param
      [id, name.parameterize].join("-")
    end

    def as_json(options = { })
      h = super(options)
      if !options.key?(:simple)
        h[:projects_num] = program_entries.count
        h[:to_param] = to_param
        h[:functions] = program_entry_people.map{ |pep| pep.function }.join(',')
        h[:updater_name] = updater ? updater.full_name : ( creator ? creator.full_name : ( import_foreign_db_name.blank? ? '' : import_foreign_db_name ) )
      end
      if !options.key?(:simple_plus)
        h[:ensemble_names] = ensembles.map{ |e| e.name }.join(',')
      end
      h[:name] = name
      
      h
    end

    private

    def convert_zip_gkz
      return if zip.blank?
      if conversion = Iox::TspGkzZipConversion.where( "zip >= ?", zip ).limit(1).order(:zip).first
        self.gkz = conversion.gkz
        if conversion.zip != zip
          Iox::TspGkzZipConversion.create zip: zip, gkz: conversion.gkz
        end
      else
        puts "person failed to find conversion for #{zip} #{city} #{name}"
      end
    end

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

  end

end
