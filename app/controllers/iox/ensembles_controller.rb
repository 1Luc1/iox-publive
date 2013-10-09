require_dependency "iox/application_controller"

module Iox
  class EnsemblesController < Iox::ApplicationController

    before_filter :authenticate!

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

      @ensembles = Ensemble.where( @query ).limit( @limit ).includes(:updater).references(:iox_users).offset( (@page) * @limit ).order(@order).load

      render json: { items: @ensembles, total: @total_items, order: @order }

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

        Iox::Activity.create! user_id: current_user.id, obj_name: @ensemble.name, action: 'created', icon_class: 'icon-asterisk', obj_id: @ensemble.id, obj_type: @ensemble.class.name, obj_path: ensemble_path(@ensemble)

        flash.notice = t('ensemble.saved', name: @ensemble.name)
        if request.xhr?
          @remote = true
        else
          redirect_to edit_ensemble_path( @ensemble )
          return
        end
      else
        flash.alert = t('ensemble.saving_failed')
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
        render json: @ensemble.ensemble_people.includes(:person).references(:iox_people).order("iox_people.lastname").load
      else
        render json: []
      end
    end

    #
    # upload logo
    #
    def upload_logo
      if @ensemble = Ensemble.unscoped.where( id: params[:id] ).first
        @img = @ensemble.images.build file: params[:ensemble][:logo]
        @img.name = @img.file.original_filename
        if @img.save
          render :json => [@img.to_jq_upload('file')].to_json
        else
          render :json => [{:error => "custom_failure"}], :status => 304
        end
      else
        render :json => [{:error => 'not found'}], :status => 404
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

    private

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

    def ensemble_params
      params.require(:ensemble).permit([:email, :name, :zip, :city, :street, :url, :country, :description, :organizer, :facebook_url, :google_plus_url, :youtube_url, :twitter_url, :lat, :lng, :notify_me_on_change, :others_can_change, :phone])
    end

  end
end