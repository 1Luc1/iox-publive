module Iox
  class InstagramPostsController < Iox::ApplicationController
    before_action :authenticate!
    layout 'iox/application'

    def index
      return if !redirect_if_no_rights

      instagram_helper = InstagramHelper.new()

      @access_token_escaped = instagram_helper.access_token_escaped
      @access_token_expires_at = instagram_helper.access_token_expires_at
      @content_publishing_current_usage = instagram_helper.content_publishing_current_usage

      @posted_on_instagram = Iox::InstagramPost.all()
     
      @upcoming_posts = Iox::ProgramEvent.postable_on_instagram.order(:starts_at)

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
