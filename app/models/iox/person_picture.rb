module Iox
  class PersonPicture < ActiveRecord::Base

    Paperclip.interpolates :person_id do |attachment, style|
      attachment.instance.person_id
    end

    include Iox::FileObject

    # paperclip plugin
    has_attached_file :file,
                      :styles => Rails.configuration.iox.venue_picture_sizes,
                      :default_url => "/images/:style/missing.png",
                      :url => "/data/:class/:person_id/:style/:updated_at_:basename.:extension"

    validates_attachment :file,
                        attachment_presence: true,
                        content_type: { :content_type => ['image/jpg', 'image/png', 'image/jpeg', 'image/gif'] },
                        size: { in: 0..10.megabytes },
                        on: :create

    belongs_to :ensemble

  end
end