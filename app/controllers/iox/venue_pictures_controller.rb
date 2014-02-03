require_dependency "iox/application_controller"

module Iox

  class VenuePicturesController < Iox::ApplicationController

    def index
      if @parent = get_parent
        render json: @parent.images.map{ |i| i.to_jq_upload('file') }
      else
        logger.error "parent element not found (#{params[:id]}) when trying to collect images"
        render json: []
      end
    end

    def create
      if @parent = get_parent
        @img = @parent.images.build file: params[:file]
        @img.name = @img.file.original_filename
        if @img.save
          render :json => [@img.to_jq_upload('file')].to_json
        else
          render :json => [{:error => "custom_failure"}], :status => 304
        end
      else
        logger.error "parent element not found (#{params[:id]}) when trying to collect images"
        render json: []
      end
    end

    def update
      if @pic = VenuePicture.find_by_id( params[:id] )
        @pic.attributes = file_params
        @pic.updated_by = current_user.id
        if @pic.save
          flash.now.notice = t('saved', name: @pic.name)
        else
          flash.now.alert = t('saving_failed', name: @pic.name)
        end
      else
        flash.now.alert = t('not_found')
      end
      render json: { flash: flash, success: !flash.notice.blank?, item: @pic }
    end

    def destroy
      if @pic = VenuePicture.find_by_id( params[:id] )
        if @pic.destroy
          flash.now.notice = t('deleted', name: @pic.name)
        else
          flash.now.alert = t('deletion_failed')
        end
      else
        flash.now.alert = t('not_found')
      end
      render json: { flash: flash, success: !flash.notice.blank? }
    end

    private

    def file_params
      params[:image].permit([:description,:copyright,:name])
    end

    def get_parent
      if params[:ensemble_id]
        return Ensemble.unscoped.where( id: params[:ensemble_id] ).first
      elsif params[:venue_id]
        return Venue.unscoped.where( id: params[:venue_id] ).first
      elsif params[:person_id]
        return Person.unscoped.where( id: params[:person_id] ).first
      end
    end
    
  end

end