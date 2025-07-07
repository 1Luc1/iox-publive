module Iox
  class ProgramFile < ActiveRecord::Base

    Paperclip.interpolates :program_entry_id do |attachment, style|
      attachment.instance.program_entry_id
    end

    Paperclip.interpolates :program_entry_id_part do |attachment, style|
      part = attachment.instance.program_entry_id.to_s
      return part[0..1] if part.size > 2
      return "0#{part}" if part.size < 2
      return part
    end

    include Iox::FileObject

    # paperclip plugin
    has_attached_file :file,
                      :styles => Rails.configuration.iox.program_file_sizes,
                      :default_url => "/images/:style/missing.png",
                      :url => "/data/:class/:program_entry_id_part/:program_entry_id/:style/:updated_at_:basename.:extension",
                      :restricted_characters => /[&$+,\/:;=?@<>\[\]\{\}\|\\\^~%# äöüÄÖÜß]/
                      # default value plus umlaute will be escaped with underscore _


    validates_attachment :file,
                        attachment_presence: true,
                        dimensions: { :width => 300, :height => 300 },
                        content_type: { :content_type => ['image/jpg', 'image/png', 'image/jpeg', 'image/gif'] },
                        size: { in: 0..10.megabytes },
                        on: :create
    validate :aspect_ratio,  if: -> { !sync_id.presence }

    belongs_to :program_entry

    protected
    def aspect_ratio
      if !file.content_type.nil? && (file.content_type.include? "image") && !file.queued_for_write[:original].nil?
        dimensions = Paperclip::Geometry.from_file(file.queued_for_write[:original].path)
        aspect_ratio_number = dimensions.width / dimensions.height
        if !(aspect_ratio_number >= 0.8 && aspect_ratio_number <= 1.91)
          errors.add(:file, "Das Seitenverhältnis des Bildes muss zwischen 4:5 und 1,91:1 (bzw. 0.8 und 1.91) liegen.")
        end
      end
    end

  end
end