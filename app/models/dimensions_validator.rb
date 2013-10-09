class DimensionsValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless record.import_file_url.blank?
    if value.queued_for_write[:original].blank?
      record.errors[attribute] << 'no file present'
      return
    end
    # I'm not sure about this:
    dimensions = Paperclip::Geometry.from_file(value.queued_for_write[:original].path)
    # But this is what you need to know:
    width = options[:width]
    height = options[:height] 

    record.errors[attribute] << I18n.t('program_file.min_dimensions', px: "#{width}x#{height}", has_px: "#{dimensions.width.to_i}x#{dimensions.height.to_i}") if ( dimensions.width < width or dimensions.height < height )
  end
end
