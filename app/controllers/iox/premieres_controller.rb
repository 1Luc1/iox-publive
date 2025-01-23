module Iox
    class PremieresController < Iox::ApplicationController
        before_action :authenticate!
        layout 'iox/application'
       
        def index
            return if !redirect_if_no_rights
            @events = Iox::ProgramEvent.where("LOWER(event_type) LIKE '%premiere%'")
                        .where("starts_at >= ?", Time.now())
                        .includes(:program_entry, :venue)
                        .order("starts_at")
            render layout: true
        end

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