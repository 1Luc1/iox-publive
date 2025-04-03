module Iox
  class SyncersController < Iox::ApplicationController

    include Iox::SyncersHelper

    before_action :authenticate!
    layout 'iox/application'

    def index
      @syncers = Iox::Syncer.order(:name)
      unless current_user.is_admin?
        @syncers = @syncers.where( user_id: current_user.id )
      end
      @syncers.load
    end

    def edit
      @syncer = Iox::Syncer.find_by_id params[:id]
    end

    def sync
      @syncer = Iox::Syncer.find_by_id params[:id]
    end

    def now
      syncer = Iox::Syncer.find_by_id params[:id]
      if sync_log = sync_now( syncer )
        render json: { ok: sync_log.ok_entries, failed: sync_log.failed_entries, sync_log: sync_log }
      else
        render json: {}, status: 409
      end
    end

    def update
      @syncer = Iox::Syncer.find_by_id params[:id]
      if @syncer.update syncer_params
        flash[:notice] = t 'syncer.saved', name: @syncer.name
        redirect_to syncers_path unless params["settings_form"]
      else
        flash[:error] = "Einstellungen konnten nicht gespeichert werden"
        render template: 'edit'
      end
    end

    def destroy
      @syncer = Iox::Syncer.find_by_id params[:id]
      if @syncer.destroy
        flash[:notice] = t 'syncer.deleted', name: @syncer.name
      else
        flash[:error] = "Einstellungen konnten nicht gespeichert werden"
      end
      redirect_to syncers_path
    end

    def new
      @syncer = Iox::Syncer.new
    end

    def create
      @syncer = Iox::Syncer.new( syncer_params )
      @syncer.user_id = current_user.id
      if @syncer.save
        flash[:notice] = t 'syncer.saved', name: @syncer.name
        redirect_to syncers_path
      else
        flash[:error] = "Einstellungen konnten nicht gespeichert werden"
      end
    end

    def settings_for
      check_404_and_privileges
      @obj = @syncer
      render template: '/iox/syncers/settings_for', layout: false
    end

    private

    def syncer_params
      params.require(:syncer).permit(
        %w( name cron_line url festival_id send_report send_report_to user_id )
      )
    end

    def check_404_and_privileges(hard_check=false)
      @insufficient_rights = true
      unless @syncer = Syncer.unscoped.where( id: params[:id] ).first
        if request.xhr?
          flash.now.alert = t('not_found')
        else
          flash.alert = t('not_found')
          redirect_to syncers_path
        end
        return false
      end

      if !current_user.is_admin? && @syncer.user_id != current_user.id && hard_check
        if request.xhr?
          flash.now.alert = t('insufficient_rights_you_cannot_save')
        else
          flash.alert = t('insufficient_rights_you_cannot_save')
          redirect_to syncers_path
        end
        return false
      end
      @insufficient_rights = false
      true
    end

  end
end
