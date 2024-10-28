module Iox
  class ProgramEntryEventsController < Iox::ApplicationController

    before_action :authenticate!

    def create
      if pe_event_params[:program_event_id].blank?
        flash.now.alert = t('program_entry_event.no_event_given')
      else
        @pe_event = ProgramEntryEvent.new pe_event_params
        if @pe_event.save
          @json_event = { id: @pe_event.id, entry_name: @pe_event.event.program_entry.title, venue_name: @pe_event.event.venue.name, starts_at: @pe_event.event.starts_at }.to_json
        else
          flash.now.alert = t('program_entry_event.saving_failed')
        end
      end
      render template: '/iox/program_events/create'
    end

    def destroy
      @pe_event = ProgramEntryEvent.find_by_id params[:id]
      if @pe_event.destroy
        flash.now.notice = t('program_entry_event.deleted')
        render json: { flash: flash, success: true }
      else
        flash.now.alert = t('program_entry_event.deletion_failed')
        render json: { flash: flash, success: false }
      end
    end

    private

    def pe_event_params
      params.require(:program_entry_event).permit([:program_event_id, :program_entry_id])
    end

  end
end