module Iox
  class VenuePicture < ActiveRecord::Base

    Paperclip.interpolates :venue_id do |attachment, style|
      attachment.instance.venue_id
    end

    include Iox::FileObject

    belongs_to  :creator, class_name: 'Iox::User', foreign_key: 'created_by'
    belongs_to  :updater, class_name: 'Iox::User', foreign_key: 'updated_by'

    # paperclip plugin
    has_attached_file :file,
                      :styles => Rails.configuration.iox.venue_picture_sizes,
                      :default_url => "/images/:style/missing.png",
                      :url => "/data/:class/:venue_id/:style/:updated_at_:basename.:extension"

    validates_attachment :file,
                        attachment_presence: true,
                        content_type: { :content_type => ['image/jpg', 'image/png', 'image/jpeg', 'image/gif'] },
                        size: { in: 0..10.megabytes },
                        on: :create

    belongs_to :venue

  end
end