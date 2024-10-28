require_dependency "iox/application_controller"

module Iox
  class VenuesController < Iox::ApplicationController

    before_action :authenticate!

    def index

      return unless request.xhr?

      @query = ''
      filter = (params[:filter] && params[:filter][:filters] && params[:filter][:filters]['0'] && params[:filter][:filters]['0'][:value]) || ''
      unless filter.blank?
        filter = filter.downcase
        if filter.match(/^[\d]*$/)
          @query = "iox_venues.import_foreign_db_id LIKE '#{filter}%' OR iox_venues.id =#{filter}"
        else
          @query = "LOWER(iox_venues.name) LIKE '%#{filter}%' OR LOWER(iox_venues.city) LIKE '%#{filter}%' OR LOWER(iox_venues.meta_keywords) LIKE '%#{filter}%'"
        end
      end

      @only_mine = !params[:only_mine] || params[:only_mine] == 'true'
      @conflict = params[:conflict] && params[:conflict] == 'true'
      @future_only = params[:future_only] && params[:future_only] == 'true'
      @only_unpublished = params[:only_unpublished] && params[:only_unpublished] == 'true'
      @q = "only_mine=#{@only_mine}&future_only=#{@future_only}&only_unpublished=#{@only_unpublished}&query=#{filter}"
      if @only_mine
        @query << " AND " if @query.size > 0
        @query << " iox_venues.created_by = #{current_user.id}"
      end
      if @conflict
        @query << " AND " if @query.size > 0
        @query << " (iox_venues.conflict IS TRUE OR iox_venues.conflict_id IS NOT NULL)"
      end
      @total_items = Venue.where( @query ).count
      @page = (params[:skip] || 0).to_i
      @page = @page / params[:pageSize].to_i if @page > 0 && params[:pageSize]
      @limit = (params[:take] || 20).to_i
      @total_pages = @total_items/@limit
      @total_pages += 1 if ((@total_items % @limit) > 0)

      @order = 'iox_venues.id'
      if params[:sort]
        sort = params[:sort]['0'][:field]
        unless sort.blank?
          sort = "iox_venues.#{sort}" if sort.match(/updated_at|id/)
          sort = "LOWER(name)" if sort === 'name'
          sort = "LOWER(iox_users.username)" if sort == 'updater_name'
          @order = "#{sort} #{params[:sort]['0'][:dir]}"
        end
      end

      @ensembles = Venue.where( @query ).limit( @limit ).includes(:updater).references(:iox_users).offset( (@page) * @limit ).order(@order).load

      render json: { items: @ensembles, total: @total_items, order: @order }

    end

    def new
      @obj = Venue.new country: 'at', name: (params[:name] || '')
      @hidden_fields = [:country]
      render template: 'iox/common/new_form', layout: false
    end

    def create
      @venue = Venue.new venue_params
      @venue.created_by = current_user.id
      if @venue.save

        Iox::Activity.create! user_id: current_user.id, obj_name: @venue.name, action: 'created', icon_class: 'icon-map-marker', obj_id: @venue.id, obj_type: @venue.class.name, obj_path: venue_path(@venue)

        flash.now.notice = t('venue.saved', name: @venue.name)
        if request.xhr?
          @remote = true
        else
          redirect_to edit_venue_path( @venue )
        end
      else
        flash.now.alert = t('venue.saving_failed')
        unless request.xhr?
          render template: 'iox/venues/new'
        end
      end
    end

    def simple
      @query = ''
      filter = (params[:filter] && params[:filter][:filters] && params[:filter][:filters]['0'] && params[:filter][:filters]['0'][:value]) || ''
      @venues = Venue
      unless filter.blank?
        filter = filter.downcase
        @venues = @venues.where("LOWER(name) LIKE ? OR LOWER(city) LIKE ?", "%#{filter}%", "%#{filter}%")
      end

      render json: @venues.order(:name).load
    end

    def edit
      check_404_and_privileges
      @layout = (!params[:layout] || params[:layout] === 'true')
      render layout: @layout
    end

    def settings_for
      check_404_and_privileges
      @obj = @venue
      render template: '/iox/program_entries/settings_for', layout: false
    end

    def update
      if check_404_and_privileges
        @venue.updater = current_user
        @venue.attributes = venue_params

        if params[:with_user]
          @venue.created_by = params[:with_user]
        end

        if params[:transfer_to_venue_id] && !params[:transfer_to_venue_id].blank?
          if @receipient = Iox::Venue.where(id: params[:transfer_to_venue_id]).first
            venue_count = 0
            @venue.program_events.each do |event|
              event.venue = @receipient
              venue_count += 1 if event.save
            end
            flash.now.notice = t('venue.transfered', count: venue_count, name: @receipient.name)

            Iox::Activity.create! user_id: current_user.id, obj_name: @venue.name, action: 'moved_events', icon_class: 'icon-map-marker', obj_id: @venue.id, obj_type: @venue.class.name, obj_path: venue_path(@receipient), recipient_name: @receipient.name
            @venue.save
            return

          else
            flash.now.alert = t('venue.transfer_target_not_found_aborted')
            return
          end
        end
        if @venue.save
          Iox::Activity.create! user_id: current_user.id, obj_name: @venue.name, action: 'updated', icon_class: 'icon-map-marker', obj_id: @venue.id, obj_type: @venue.class.name, obj_path: venue_path(@venue)

          flash.now.notice = t('venue.saved', name: @venue.name)
          flash.now.notice = t('settings_saved', name: @venue.name) if params[:settings_form]
          redirect_to edit_venue_path( @venue ) unless request.xhr?
        else
          flash.now.alert = t('venue.saving_failed')
          flash.now.alert = t('settings_saved', name: @venue.name) if params[:settings_form]
          render template: 'iox/venues/edit' unless request.xhr?
        end
      else
        redirect_to venues_path unless request.xhr?
      end
    end

    def members_of
      if @venue = Venue.unscoped.where( id: params[:id] ).first
        render json: @venue.members.load.to_json
      else
        render json: []
      end
    end

    def destroy
      if check_404_and_privileges true
        if @venue && @venue.delete

          Iox::Activity.create! user_id: current_user.id, obj_name: @venue.name, action: 'deleted', icon_class: 'icon-map-marker', obj_id: @venue.id, obj_type: @venue.class.name, obj_path: venue_path(@venue)

          flash.now.notice = t('venue.deleted', name: @venue.name, id: @venue.id)
        else
          flash.now.alert = t('venue.deletion_failed', name: @venue.name)
        end
      end
      render json: { success: !flash.alert, flash: flash }
    end

    def restore
      if check_404_and_privileges

        if @venue.restore

          Iox::Activity.create! user_id: current_user.id, obj_name: @venue.name, action: 'restored', icon_class: 'icon-map-marker', obj_id: @venue.id, obj_type: @venue.class.name, obj_path: venue_path(@venue)

          flash.now.notice = t('venue.restored', name: @venue.name)
        else
          flash.now.alert = t('venue.failed_to_restore', name: @venue.name)
        end
      end
    end


    private

    def check_404_and_privileges(hard_check=false)
      @insufficient_rights = true
      unless @venue = Venue.unscoped.where( id: params[:id] ).first
        if request.xhr?
          flash.now.alert = t('not_found')
        else
          flash.alert = t('not_found')
          redirect_to ensembles_path
        end
        return false
      end
      if !current_user.is_admin? && @venue.created_by != current_user.id && (!@venue.others_can_change || hard_check)
        if request.xhr?
          flash.now.alert = t('insufficient_rights_you_cannot_save')
        else
          flash.alert = t('insufficient_rights_you_cannot_save')
          redirect_to ensembles_path
        end
        return false
      end
      @insufficient_rights = false
      true
    end

    def venue_params
      params.require(:venue).permit([:email, :name, :zip, :city, :street, :url, :description, :country, :lat, :lng, :phone, :tickets_url, :facebook_url, :twitter_url, :youtube_url, :google_plus_url, :notify_me_on_change, :others_can_change, :archived])
    end

  end
end