module Iox
    class PremieresController < Iox::ApplicationController
        before_action :authenticate!
        layout 'iox/application'
       
        def index
            return if !redirect_if_no_rights
            @filter = "magazin"
            if params.has_key?(:filter) && ["all", "magazin", "newsletter"].include?(params["filter"])
                @filter = params["filter"]
            end
            @events = Iox::ProgramEvent.where("LOWER(event_type) LIKE '%premiere%'")
                        .where("iox_program_events.starts_at >= ?", Time.now())
                        .joins(:program_entry, :venue)
                        .order("iox_program_events.starts_at")
            if @filter == 'magazin'
                @events = @events.where("show_in_magazin = true")
            end
            if @filter == 'newsletter'
                @events = @events.where("show_in_newsletter = true")
            end

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