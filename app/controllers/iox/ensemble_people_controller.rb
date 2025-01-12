module Iox
  class EnsemblePeopleController < Iox::ApplicationController

    before_action :authenticate!

    def create
      if params[:person] && params[:person][:name] && params[:person][:name].include?(' ')
        @person = Person.new firstname: params[:person][:name].split(' ')[0],
                              lastname: params[:person][:name].split(' ')[1]
        if @person.save
          @ensemble_member = EnsemblePerson.new person_id: @person.id, ensemble_id: params[:ensemble_id]
        else
          flash.now.alert = t('program_entry_person.saving_failed')
        end
      else
        @ensemble_member = EnsemblePerson.new ensemble_member_params
      end
      if @ensemble_member && @ensemble_member.save
        flash.now.notice = t('program_entry_person.saved', name: @ensemble_member.person.name)
      else
        flash.now.alert = t('program_entry_person.saving_failed')
      end
      render json: { flash: flash, item: @ensemble_member || nil }
    end

    def update
      @ensemble_member = EnsemblePerson.find_by_id params[:id]
      @ensemble_member.updated_by = current_user.id
      @ensemble_member.attributes = ensemble_member_params
      if @ensemble_member.save
        flash.now.notice = t('program_entry_person.saved', name: @ensemble_member.person.name)
      else
        flash.now.alert = t('program_entry_person.saving_failed')
      end
      render json: { flash: flash, success: flash[:success], item: @ensemble_member }
    end

    def destroy
      @success = false
      if @ensemble_member = EnsemblePerson.where( id: params[:id] ).first
        if @ensemble_member.ensemble.created_by == current_user.id || current_user.is_admin?
          if @ensemble_member.destroy
            @success = true
            flash.now.notice = t('program_entry_person.removed', name: @ensemble_member.person.name)
          else
            flash.now.alert = t('program_entry_person.removing_failed', name: @ensemble_member.person.name)
          end
        else
          flash.now.alert = t('insufficient_rights')
        end
      else
        flash.now.alert = t('not_found')
      end
      render json: { flash: flash, success: @success }
    end

    private

    def ensemble_member_params
      params.require(:ensemble_person).permit([:function, :person_id, :ensemble_id, :membership_start, :memership_end])
    end

  end
end