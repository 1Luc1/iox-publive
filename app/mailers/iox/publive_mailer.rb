module Iox
  class PubliveMailer < ActionMailer::Base

    def content_changed( obj, changes )
      return unless ( obj.creator || obj.creator.email.blank? )
      return unless ( obj.updater || obj.updater.email.blank? )
      @obj = obj
      @recipient = obj.creator
      @took_action = obj.updater
      @changes = changes
      mail( to: @recipient.email, subject: "[#{Rails.configuration.iox.site_title}] #{I18n.t('obj.mailer.subject')}" )
    end

  end
end
