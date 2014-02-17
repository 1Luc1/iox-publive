module Iox
  class Person < ActiveRecord::Base

    acts_as_iox_document

    include Iox::FileObject

    has_many :program_entry_people, dependent: :destroy
    has_many :program_entries, through: :program_entry_people

    has_many :ensemble_people
    has_many :ensembles, through: :ensemble_people

    belongs_to :creator, class_name: 'Iox::User', foreign_key: 'created_by'
    belongs_to  :updater, class_name: 'Iox::User', foreign_key: 'updated_by'

    # paperclip plugin
    has_attached_file :avatar,
                      :styles => Rails.configuration.iox.person_picture_sizes,
                      :default_url => "/images/:style/missing.png",
                      :url => "/data/iox/person_avatars/:hash.:extension",
                      :hash_secret => "5b1b59b59b08dfef721470feed062327909b8f92"

    #validates :firstname, presence: true
    validates :lastname, presence: true

    after_save :notify_owner_by_email

    has_many    :images, -> { order(:position) }, class_name: 'Iox::PersonPicture', dependent: :destroy

    def name
      "#{firstname}#{" " if !firstname.blank? && !lastname.blank?}#{lastname}"
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
        self.firstname = full_name.split(' ')[0]
        self.lastname = full_name.split(' ')[1]
      else
        self.lastname = full_name
      end
    end

    def to_param
      [id, name.parameterize].join("-")
    end

    def as_json(options = { })
      h = super(options)
      h[:name] = name
      h[:projects_num] = program_entries.count
      h[:to_param] = to_param
      h[:functions] = program_entry_people.map{ |pep| pep.function }.join(',')
      h[:updater_name] = updater ? updater.full_name : ( creator ? creator.full_name : ( import_foreign_db_name.blank? ? '' : import_foreign_db_name ) )
      h[:ensemble_names] = ensembles.map{ |e| e.name }.join(',')
      h
    end

    private

    def notify_owner_by_email
      if updater && creator && updater.id != creator.id && notify_me_on_change
        Iox::PubliveMailer.content_changed( self, changes ).deliver
      end
    end

  end

end
