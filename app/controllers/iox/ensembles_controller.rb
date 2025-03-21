require_dependency "iox/application_controller"

module Iox
  class EnsemblesController < Iox::ApplicationController

    before_action :authenticate!

    def index

      return unless request.xhr?

      @query = ''
      filter = (params[:filter] && params[:filter][:filters] && params[:filter][:filters]['0'] && params[:filter][:filters]['0'][:value]) || ''
      unless filter.blank?
        filter = filter.downcase
        if filter.match(/^[\d]*$/)
          @query = "iox_ensembles.import_foreign_db_id LIKE '#{filter}%' OR iox_ensembles.id =#{filter}"
        else
          @query = "LOWER(iox_ensembles.name) LIKE '%#{filter}%' OR LOWER(iox_ensembles.city) LIKE '%#{filter}%' OR LOWER(iox_ensembles.meta_keywords) LIKE '%#{filter}%'"
        end
      end

      @only_mine = !params[:only_mine] || params[:only_mine] == 'true'
      @conflict = params[:conflict] && params[:conflict] == 'true'
      @future_only = params[:future_only] && params[:future_only] == 'true'
      @only_unpublished = params[:only_unpublished] && params[:only_unpublished] == 'true'
      @q = "only_mine=#{@only_mine}&future_only=#{@future_only}&only_unpublished=#{@only_unpublished}&query=#{filter}"
      if @only_mine
        @query << " AND " if @query.size > 0
        @query << " iox_ensembles.created_by = #{current_user.id}"
      end
      if @conflict
        @query << " AND " if @query.size > 0
        @query << " (iox_ensembles.conflict IS TRUE OR iox_ensembles.conflict_id IS NOT NULL)"
      end
      @total_items = Ensemble.where( @query ).count
      @page = (params[:skip] || 0).to_i
      @page = @page / params[:pageSize].to_i if @page > 0 && params[:pageSize]
      @limit = (params[:take] || 20).to_i
      @total_pages = @total_items/@limit
      @total_pages += 1 if ((@total_items % @limit) > 0)

      @order = 'iox_ensembles.id'
      if params[:sort]
        sort = params[:sort]['0'][:field]
        unless sort.blank?
          sort = "iox_ensembles.#{sort}" if sort.match(/updated_at/)
          sort = "LOWER(name)" if sort === 'name'
          sort = "LOWER(iox_users.username)" if sort == 'updater_name'
          @order = "#{sort} #{params[:sort]['0'][:dir]}"
        end
      end

      @ensembles = Ensemble.where( @query ).limit( @limit ).includes(:updater).offset( (@page) * @limit ).order(@order).load

      render json: { items: @ensembles, total: @total_items, order: @order }

    end

    def simple
      @query = ''
      filter = (params[:filter] && params[:filter][:filters] && params[:filter][:filters]['0'] && params[:filter][:filters]['0'][:value]) || ''
      @ensembles = Ensemble
      unless filter.blank?
        filter = filter.downcase
        @ensembles = @ensembles.where("LOWER(name) LIKE ?", "%#{filter}%")
      end
      render json: @ensembles.order(:name).load
    end


    def new
      @obj = Ensemble.new country: 'at'
      @hidden_fields = [:country]
      render template: 'iox/common/new_form', layout: false
    end

    def create
      @ensemble = Ensemble.new ensemble_params
      @ensemble.created_by = current_user.id
      if @ensemble.save
        begin
          Iox::Activity.create! user_id: current_user.id, obj_name: @ensemble.name, action: 'created', icon_class: 'icon-asterisk', obj_id: @ensemble.id, obj_type: @ensemble.class.name, obj_path: ensemble_path(@ensemble)
        rescue
        end

        flash.notice = t('ensemble.saved', name: @ensemble.name)
        if request.xhr?
          @remote = true
        else
          redirect_to edit_ensemble_path( @ensemble )
          return
        end
      else
        flash.alert = "#{t('ensemble.saving_failed')}: #{@ensemble.errors.full_messages.join(' ').html_safe}"
        unless request.xhr?
          render template: 'iox/ensembles/new', layout: false
          return
        end
      end
    end

    def edit
      check_404_and_privileges
      @layout = (!params[:layout] || params[:layout] === 'true')
      render layout: @layout
    end

    def settings_for
      check_404_and_privileges
      @obj = @ensemble
      render template: '/iox/program_entries/settings_for', layout: false
    end

    def update
      if check_404_and_privileges
        @ensemble.attributes = ensemble_params
        @ensemble.updated_by = current_user.id

        if params[:with_user]
          @ensemble.created_by = params[:with_user]
        end

        # ATTENTION! the param is still called transfer_to_venue_id
        # as it is processed in the same javascript function
        if params[:transfer_to_venue_id] && !params[:transfer_to_venue_id].blank?
          if @receipient = Iox::Ensemble.where(id: params[:transfer_to_venue_id]).first
            entries_count = 0
            @ensemble.program_entries.each do |program_entry|
              program_entry.ensemble = @receipient
              entries_count += 1 if program_entry.save
            end
            flash.now.notice = t('ensemble.transfered', count: entries_count, name: @receipient.name)

            Iox::Activity.create! user_id: current_user.id, obj_name: @ensemble.name, action: 'moved_entries', icon_class: 'icon-asterisk', obj_id: @ensemble.id, obj_type: @ensemble.class.name, obj_path: venue_path(@receipient), recipient_name: @receipient.name
            @ensemble.save
            return

          else
            flash.now.alert = t('venue.transfer_target_not_found_aborted')
            return
          end
        end

        if @ensemble.save

          Iox::Activity.create! user_id: current_user.id, obj_name: @ensemble.name, action: 'updated', icon_class: 'icon-asterisk', obj_id: @ensemble.id, obj_type: @ensemble.class.name, obj_path: ensemble_path(@ensemble)

          flash.notice = t('ensemble.saved', name: @ensemble.name)
          flash.notice = t('settings_saved', name: @ensemble.name) if params[:settings_form]
          redirect_to edit_ensemble_path( @ensemble ) unless request.xhr?
        else
          flash.alert = t('ensemble.saving_failed')
          flash.alert = t('settings_saving_failed', name: @ensemble.name) if params[:settings_form]
          render template: 'iox/ensembles/edit' unless request.xhr?
        end
      end
    end

    def members_of
      if @ensemble = Ensemble.unscoped.where( id: params[:id] ).first

        @ensemble_people = @ensemble.ensemble_people.includes(:person).references(:iox_people).order("iox_people.lastname").load
        # swipe out entries where person behind has gone
        @ensemble_people.each do |epe|
          epe.destroy unless epe.person
        end

        render json: @ensemble_people
      else
        render json: []
      end
    end

    def destroy
      if check_404_and_privileges true
        if @ensemble && @ensemble.delete

          Iox::Activity.create! user_id: current_user.id, obj_name: @ensemble.name, action: 'deleted', icon_class: 'icon-asterisk', obj_id: @ensemble.id, obj_type: @ensemble.class.name, obj_path: ensemble_path(@ensemble)

          flash.now.notice = t('ensemble.deleted', name: @ensemble.name, id: @ensemble.id)
        else
          flash.now.alert = t('ensemble.deletion_failed', name: @ensemble.name)
        end
      end
      render json: { success: !flash[:notice].blank?, flash: flash }
    end

    def restore
      if check_404_and_privileges

        if @ensemble.restore

          Iox::Activity.create! user_id: current_user.id, obj_name: @ensemble.name, action: 'restored', icon_class: 'icon-asterisk', obj_id: @ensemble.id, obj_type: @ensemble.class.name, obj_path: ensemble_path(@ensemble)

          flash.now.notice = t('ensemble.restored', name: @ensemble.name)
        else
          flash.now.alert = t('ensemble.failed_to_restore', name: @ensemble.name)
        end
      end
    end

    def merge
      return unless is_admin
      @ensembles = Ensemble.select("name")
                          .select("count(name) AS cnt")
                          .select("GROUP_CONCAT(iox_ensembles.id) as ids")
                          .group("name")
                          .order("iox_ensembles.id ASC")
                          .having("cnt > 1")
                          .load
      @merged_ensembles = Ensemble.unscoped
                        .where("time(deleted_at) = '00:00:00'")
                        .where("conflicting_with_id is not null")
                        .group("conflicting_with_id").load
      render layout: true
    end

    def merged
      return unless is_admin
      @ensembles = Ensemble.select("iox_ensembles.id, iox_ensembles.name")
              .select("count(iox_ensembles.name) AS cnt")
              .select("GROUP_CONCAT(refe.id) as ids")
              .select("DATE(MIN(refe.deleted_at)) as merged_at")
              .joins("LEFT JOIN iox_ensembles as refe ON refe.conflicting_with_id = iox_ensembles.id")
              .where("iox_ensembles.conflicting_with_id = 0")
              .group("iox_ensembles.name")
              .order("iox_ensembles.id ASC")
              .load
      render layout: true
    end

    def merge_selected
      return unless is_admin
      if !params[:ids]
        @nothing_selected = true
        flash.notice = t('ensembles.no_ensembles_selected')
      else
        logger = get_loger("merge")
        logger.info "Start merging #{params[:ids].count} ensembles duplicats"
        error_occoured = false
        params[:ids].each do |ids|
          # sort ids asc; first will be main ensemble to merge into
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
          ensemble_people = Array.new
          program_entries = Array.new

          sort_ids.each do |id|
            ensemble = Ensemble.find(id)

            url = ensemble.url unless ensemble.url.nil?
            email = ensemble.email unless ensemble.email.nil?
            description = ensemble.description unless ensemble.description.nil?
            phone = ensemble.phone unless ensemble.phone.nil?
            zip = ensemble.zip unless ensemble.zip.nil?
            city = ensemble.city unless ensemble.city.nil?
            street = ensemble.street unless ensemble.street.nil?
            twitter_url = ensemble.twitter_url unless ensemble.twitter_url.nil?
            facebook_url = ensemble.facebook_url unless ensemble.facebook_url.nil?
            youtube_url = ensemble.youtube_url unless ensemble.youtube_url.nil?
            # deep copy releations to preserve db entries for merged ensembles
            ensemble.ensemble_people.each{|e| ensemble_people << e.dup}
            ensemble.program_entries.each{|e| program_entries << e.dup}
         
            # set conflicting_with_id for merged ensemble before delete
            ensemble.conflicting_with_id = main_id
            ensemble.clean
          end

          main_ensemble = Ensemble.find(main_id)
         
          main_ensemble.url = url if !url.empty? && (main_ensemble.url.nil? || main_ensemble.url.empty?)
          main_ensemble.email = email if !email.empty? && (main_ensemble.email.nil? || main_ensemble.email.empty?)
          main_ensemble.description = description if !description.empty? && (main_ensemble.description.nil? || main_ensemble.description.empty?)
          main_ensemble.phone = phone if !phone.empty? && (main_ensemble.phone.nil? || main_ensemble.phone.empty?)
          main_ensemble.zip = zip if !zip.empty? && (main_ensemble.zip.nil? || main_ensemble.zip.empty?)
          main_ensemble.city = city if !city.empty? && (main_ensemble.city.nil? || main_ensemble.city.empty?)
          main_ensemble.street = street if !street.empty? && (main_ensemble.street.nil? || main_ensemble.street.empty?)
          main_ensemble.twitter_url = twitter_url if !twitter_url.empty? && (main_ensemble.twitter_url.nil? || main_ensemble.twitter_url.empty?)
          main_ensemble.facebook_url = facebook_url if !facebook_url.empty? && (main_ensemble.facebook_url.nil? || main_ensemble.facebook_url.empty?)
          main_ensemble.youtube_url = youtube_url if !youtube_url.empty? && (main_ensemble.youtube_url.nil? || main_ensemble.youtube_url.empty?)
          main_ensemble.ensemble_people << ensemble_people
          main_ensemble.program_entries << program_entries

          main_ensemble.conflicting_with_id = 0
          
          if !main_ensemble.save
              logger.error "main_ensemble.ID(#{main_id}): #{main_ensemble.errors.full_messages.join(' ')}"
              error_occoured = true
          end
        end unless params[:ids].blank?
        logger.info "Finished merging"
        if error_occoured
          flash.alert = t('process_error')
        else
          flash.notice = t('ensembles.merged', cnt: params[:ids].count)
        end
      end
      redirect_to merge_ensembles_path
    end

    def clean
      return unless is_admin
      @ensembles = Ensemble.select("iox_ensembles.id, name").left_outer_joins( :ensemble_people, :program_entries)
      .where(iox_program_entries: { id: nil })
      .where(iox_ensemble_people: { id: nil })
      .where("(`iox_ensembles`.`email` = '' OR `iox_ensembles`.`email` IS NULL) AND (`iox_ensembles`.`phone`= '' OR `iox_ensembles`.`phone` IS NULL) AND (`iox_ensembles`.`zip`= '' OR `iox_ensembles`.`zip` IS NULL)")

      @cleaned_ensembles = Ensemble.unscoped.where("time(deleted_at) = '00:00:00'").where("conflicting_with_id is null")

      render layout: true
    end

    def clean_selected
      return unless is_admin
      if !params[:ids]
        @nothing_selected = true
        flash.notice = t('ensembles.no_ensembles_selected')
      else
        logger = get_loger("clean")
        logger.info "Start cleaning #{params[:ids].count} ensembles"
        error_occoured = false
        params[:ids].each do |id|
          ensemble = Ensemble.find(id)
          if !ensemble.clean
            logger.error "Ensemble.ID(#{id}): #{ensemble.errors.full_messages.join(' ')}"
            error_occoured = true
          end
        end unless params[:ids].blank?
        logger.info "Finished cleaning"
        if error_occoured
          flash.alert = t('process_error')
        else
          flash.notice = t('ensembles.deleted', cnt: params[:ids].count)
        end
      end
      redirect_to clean_ensembles_path
    end

    private
    def get_loger(type)
      Logger.new("#{Rails.root}/log/ensembles_#{type}.log")
    end

    def check_404_and_privileges( hard_check=false )
      @insufficient_rights = true
      unless @ensemble = Ensemble.unscoped.where( id: params[:id] ).first
        if request.xhr?
          flash.now.alert = t('not_found')
        else
          flash.alert = t('not_found')
          redirect_to ensembles_path
        end
        return false
      end
      if !current_user.is_admin? && @ensemble.created_by != current_user.id && (!@ensemble.others_can_change || hard_check)
        @insufficient_rights = true
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

    def ensemble_params
      params.require(:ensemble).permit([:email, :name, :zip, :city, :street, :url, :country, :description, :organizer, :facebook_url, :google_plus_url, :youtube_url, :twitter_url, :lat, :lng, :notify_me_on_change, :others_can_change, :phone])
    end

  end
end