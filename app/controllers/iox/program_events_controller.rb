module Iox
  class ProgramEventsController < Iox::ApplicationController

    before_filter :authenticate!

    def create
      @program_event = ProgramEvent.new program_event_params
      #@program_event.reductions = @program_event.reductions.join(',')
      #@program_event.reductions = params[:program_event][:reductions_arr].join(',') if params[:program_event][:reductions_arr] && params[:program_event][:reductions_arr].size > 0
      #@program_event.reductions = params[:program_event][:reductions_arr]
      if @program_event.save
        flash.now.notice = t('program_event.saved', starts: l(@program_event.starts_at, format: :short), venue: (@program_event.venue ? @program_event.venue.name : '') )
        @pentry = @program_event.program_entry
        if @pentry.starts_at.blank? || @program_event.starts_at.nil? || @program_event.starts_at < @pentry.starts_at
          @pentry.starts_at = @program_event.starts_at
          @pentry.save
        end
        if @pentry.ends_at.nil? || @program_event.starts_at > @pentry.ends_at
          @pentry.ends_at = @program_event.starts_at
          @pentry.save
        end
        @json_event = { id: @program_event.id, festival_name: (@program_event.festival && @program_event.festival.title), venue_name: (@program_event.venue && @program_event.venue.name), starts_at: @program_event.starts_at }.to_json
      else
        flash.now.alert = t('program_event.saving_failed')
      end
      render json: { flash: flash, item: @program_event }
    end

    def update
      @program_event = ProgramEvent.find_by_id params[:id]
      @program_event.updated_by = current_user.id
      @program_event.attributes = program_event_params
      #@program_event.reductions = @program_event.reductions.join(',') #params[:program_event][:reductions_arr] #.join(',') if params[:program_event][:reductions_arr] && params[:program_event][:reductions_arr].size > 0
      if @program_event.save
        flash.now.notice = t('program_event.saved', starts: (@program_event.starts_at ? l(@program_event.starts_at, format: :short) : ''), venue: (@program_event.venue ? @program_event.venue.name : '') )
      else
        flash.now.alert = t('program_event.saving_failed')
      end
      render json: { flash: flash, success: flash[:success], item: @program_event }
    end

    def multiply_field
      @program_event = ProgramEvent.find_by_id params[:id]
      @program_event.updated_by = current_user.id
      if params[:value] && params[:field]
        errors = 0
        @program_event.program_entry.events.each do |event|
          event.send("#{params[:field]}=", params[:value])
          errors += 1 unless event.save
        end
        if errors == 0
          flash.now.notice = t('program_event.multiplied', field: params[:field])
        else
          flash.now.alert = t('program_event.multiplying_failed', num: errors, field: params[:field])
        end
      end
      render json: { flash: flash }
    end

    def destroy
      @program_event = ProgramEvent.find_by_id( params[:id] )
      if @program_event.destroy
        flash.now.notice = t('program_event.deleted', starts: l(@program_event.starts_at, format: :short), venue: (@program_event.venue ? @program_event.venue.name : ''))
      else
        flash.now.alert = t('program_event.deletion_failed')
      end
      render json: { flash: flash, item: @program_event }
    end

    def reductions
      reductions = ['']
      Iox::ProgramEvent.group(:reductions).each do |event|
        next unless event.reductions
        event.reductions.split(',').each do |reduction|
          next if params[:q] && !reduction.include?(params[:q])
          reductions << reduction.downcase.titleize unless reductions.include?(reduction.downcase.titleize)
        end
      end
      render json: reductions.map{ |red| { id: red, text: red }}
    end

    private

    def program_event_params
      params.require(:program_event).permit([
        :starts_at, 
        :ends_at, 
        :festival_id, 
        :event_type, 
        :starts_at_time, 
        :venue_id, 
        :price_from, 
        :price_to, 
        :additional_note, 
        :program_entry_id, 
        :tickets_url, 
        :tickets_phone, 
        :tickets_email, 
        :description, 
        :reductions ])
    end

  end
end