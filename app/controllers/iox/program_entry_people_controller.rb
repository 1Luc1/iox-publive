module Iox
  class ProgramEntryPeopleController < Iox::ApplicationController

    before_filter :authenticate!

    def create
      if pe_person_params[:person_id].blank?
        flash.now.alert = t('program_entry_person.no_person_given')
      elsif pe_person_params[:function].blank?
        flash.now.alert = t('program_entry_person.no_function_given')
      else
        @pe_person = ProgramEntryPerson.new pe_person_params
        @pe_person.created_by = current_user.id
        if @pe_person.save
          flash.now.notice = t('program_entry_person.saved', name: @pe_person.person.name )
        else
          flash.now.alert = t('program_entry_person.saving_failed')
        end
      end
      render json: { flash: flash, item: @pe_person }
    end

    def update
      @pe_person = ProgramEntryPerson.find_by_id params[:id]
      @pe_person.updated_by = current_user.id
      @pe_person.attributes = pe_person_params
      if @pe_person.save
        flash.now.notice = t('program_entry_person.saved', name: @pe_person.person.name)
      else
        flash.now.alert = t('program_entry_person.saving_failed')
      end
      render json: { flash: flash, success: flash[:success], item: @pe_person }
    end

    def destroy
      @pe_person = ProgramEntryPerson.find_by_id params[:id]
      if @pe_person.destroy
        flash.now.notice = t('program_entry_person.removed', name: @pe_person.person.name)
      else
        flash.now.alert = t('program_entry_person.removing_failed')
      end
      render json: { flash: flash, success: flash[:success], item: @pe_person }
    end

    private

    def pe_person_params
      params.require(:program_entry_person).permit([:function, :person_id, :program_entry_id, :role ])
    end

  end
end