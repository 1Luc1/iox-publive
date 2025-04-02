module Iox
  class InstagramSyncsController < Iox::ApplicationController
    before_action :authenticate!
    layout 'iox/application'

    def index
      return if !redirect_if_no_rights

      instagram_helper = InstagramHelper.new()

      @access_token_escaped = instagram_helper.access_token_escaped
      @access_token_expires_at = instagram_helper.access_token_expires_at
      @content_publishing_current_usage = instagram_helper.content_publishing_current_usage

      render layout: true
    end

    private

    def redirect_if_no_rights
      if !current_user.is_admin?
        flash.alert = I18n.t('error.insufficient_rights')
        render json: { success: false, flash: flash }
        return false
      end
      true
    end
  end
end
