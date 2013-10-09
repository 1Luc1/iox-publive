require_dependency "iox/application_controller"

module Iox

  class ProgramFilesController < Iox::ApplicationController

    def destroy
      success = false
      if @program_file = ProgramFile.find_by_id( params[:id] )
        if @program_file.destroy
          flash.now.notice = t('program_file.deleted')
          success = true
        else
          flash.now.alert = t('program_file.deletion_failed')
        end
      else
        flash.now.alert = t('not_found')
      end
      render json: { flash: flash, success: success }
    end
    
  end

end