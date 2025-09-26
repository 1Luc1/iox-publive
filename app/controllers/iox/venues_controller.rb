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
        filter = quote_string(filter)
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
        flash.now.alert = "#{t('venue.saving_failed', name: @venue.name)}: #{@venue.errors.full_messages.join(' ').html_safe}"
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

        # admin can skip validation to make duplicate entries on purpose to merge them afterwards
        if @venue.save :validate => !current_user.is_admin?
          Iox::Activity.create! user_id: current_user.id, obj_name: @venue.name, action: 'updated', icon_class: 'icon-map-marker', obj_id: @venue.id, obj_type: @venue.class.name, obj_path: venue_path(@venue)

          flash.now.notice = t('venue.saved', name: @venue.name)
          flash.now.notice = t('settings_saved', name: @venue.name) if params[:settings_form]
          redirect_to edit_venue_path( @venue ) unless request.xhr?
        else
          flash.now.alert = "#{t('venue.saving_failed', name: @venue.name)}: #{@venue.errors.full_messages.join(' ').html_safe}"
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

    def merge
      return unless is_admin
      @venues = Venue.select("name")
                      .select("count(name) AS cnt")
                      .select("GROUP_CONCAT(iox_venues.id) as ids")
                      .group("name")
                      .order("iox_venues.id ASC")
                      .having("cnt > 1")
                      .load
      @merged_venues = Venue.unscoped
                            .where("time(deleted_at) = '00:00:00'")
                            .where("conflicting_with_id is not null")
                            .group("conflicting_with_id").load
      render layout: true
    end

    def merged
      return unless is_admin
      @venues = Venue.select("iox_venues.id, iox_venues.name")
              .select("count(iox_venues.name) AS cnt")
              .select("GROUP_CONCAT(refv.id) as ids")
              .select("DATE(MIN(refv.deleted_at)) as merged_at")
              .joins("LEFT JOIN iox_venues as refv ON refv.conflicting_with_id = iox_venues.id")
              .where("iox_venues.conflicting_with_id = 0")
              .group("iox_venues.name")
              .order("iox_venues.id ASC")
              .load
      render layout: true
    end

    def merge_selected
      return unless is_admin
      if !params[:ids]
        @nothing_selected = true
        flash.notice = t('venues.no_venue_selected')
      else
        logger = Logger.new("#{Rails.root}/log/merge_clean.log")
        logger.info "Start merging #{params[:ids].count} venue duplicats"
        error_occoured = false
        params[:ids].each do |ids|
          # sort ids asc; first will be main venue to merge into
          sort_ids = ids.split(/, ?/).sort_by(&:to_i)
          main_id = sort_ids.shift() 
          
          url = ""
          email = ""
          description = ""
          phone = ""
          zip = ""
          city = ""
          street = ""
          twitter_url = ""
          facebook_url = ""
          youtube_url = ""
          program_events = Array.new

          sort_ids.each do |id|
            venue = Venue.find(id)

            url = venue.url unless venue.url.nil?
            email = venue.email unless venue.email.nil?
            description = venue.description unless venue.description.nil?
            phone = venue.phone unless venue.phone.nil?
            zip = venue.zip unless venue.zip.nil?
            city = venue.city unless venue.city.nil?
            street = venue.street unless venue.street.nil?
            twitter_url = venue.twitter_url unless venue.twitter_url.nil?
            facebook_url = venue.facebook_url unless venue.facebook_url.nil?
            youtube_url = venue.youtube_url unless venue.youtube_url.nil?
            # deep copy releations to preserve db entries for merged venues 
            venue.program_events.each{|e| program_events << e.dup}
         
            # set conflicting_with_id for merged venue before delete
            venue.conflicting_with_id = main_id
            venue.clean
          end

          main_venue = Venue.find(main_id)
         
          main_venue.url = url if !url.empty? && (main_venue.url.nil? || main_venue.url.empty?)
          main_venue.email = email if !email.empty? && (main_venue.email.nil? || main_venue.email.empty?)
          main_venue.description = description if !description.empty? && (main_venue.description.nil? || main_venue.description.empty?)
          main_venue.phone = phone if !phone.empty? && (main_venue.phone.nil? || main_venue.phone.empty?)
          main_venue.zip = zip if !zip.empty? && (main_venue.zip.nil? || main_venue.zip.empty?)
          main_venue.city = city if !city.empty? && (main_venue.city.nil? || main_venue.city.empty?)
          main_venue.street = street if !street.empty? && (main_venue.street.nil? || main_venue.street.empty?)
          main_venue.twitter_url = twitter_url if !twitter_url.empty? && (main_venue.twitter_url.nil? || main_venue.twitter_url.empty?)
          main_venue.facebook_url = facebook_url if !facebook_url.empty? && (main_venue.facebook_url.nil? || main_venue.facebook_url.empty?)
          main_venue.youtube_url = youtube_url if !youtube_url.empty? && (main_venue.youtube_url.nil? || main_venue.youtube_url.empty?)
          main_venue.program_events << program_events

          main_venue.conflicting_with_id = 0
          
          if !main_venue.save
              logger.error "main_venue.ID(#{main_id}): #{main_venue.errors.full_messages.join(' ')}"
              error_occoured = true
          end
        end unless params[:ids].blank?
        logger.info "Finished merging"
        if error_occoured
          flash.alert = t('process_error')
        else
          flash.notice = t('venues.merged', cnt: params[:ids].count)
        end
      end
      redirect_to merge_venues_path
    end

    def clean
      return unless is_admin
      @venues = Venue.select("iox_venues.id, name").left_outer_joins( :program_events)
      .where(iox_program_events: { id: nil })
      .where("(`iox_venues`.`email` = '' OR `iox_venues`.`email` IS NULL) AND (`iox_venues`.`phone`= '' OR `iox_venues`.`phone` IS NULL) AND (`iox_venues`.`zip`= '' OR `iox_venues`.`zip` IS NULL)")

      @cleaned_venues = Venue.unscoped.where("time(deleted_at) = '00:00:00'").where("conflicting_with_id is null")

      render layout: true
    end

    def clean_selected
      return unless is_admin
      if !params[:ids]
        @nothing_selected = true
        flash.notice = t('venues.no_venue_selected')
      else
        logger = Logger.new("#{Rails.root}/log/merge_clean.log")
        logger.info "Start cleaning #{params[:ids].count} venues"
        error_occoured = false
        params[:ids].each do |id|
          venue = Venue.find(id)
          if !venue.clean
            logger.error "Venue.ID(#{id}): #{venue.errors.full_messages.join(' ')}"
            error_occoured = true
          end
        end unless params[:ids].blank?
        logger.info "Finished cleaning"
        if error_occoured
          flash.alert = t('process_error')
        else
          flash.notice = t('venues.deleted', cnt: params[:ids].count)
        end
      end
      redirect_to clean_venues_path
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

    def is_admin
      if !current_user.is_admin?
        @insufficient_rights = true
        flash.now.alert = t('insufficient_rights')
        return false
      end
      return true
    end

    def venue_params
      params.require(:venue).permit([:email, :name, :zip, :city, :street, :url, :description, :country, :lat, :lng, :phone, :tickets_url, :facebook_url, :twitter_url, :youtube_url, :google_plus_url, :notify_me_on_change, :others_can_change, :archived])
    end

  end
end