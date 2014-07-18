module Iox
  class SyncersController < Iox::ApplicationController

    before_filter :authenticate!
    layout 'iox/application'

    def index
      @syncers = Syncer.order(:name)
      unless current_user.is_admin?
        @syncers.where( user_id: current_user.id )
      end
    end

    def edit
      @syncer = Iox::Syncer.find_by_id params[:id]
    end

    def sync
      @syncer = Iox::Syncer.find_by_id params[:id]
    end

    def now
      @syncer = Iox::Syncer.find_by_id params[:id]
      require Rails.root.join("lib/tsp/parsers/ess/ess")
      return unless @channel = ESS.parse_file( @syncer.url ).first
      ok = []
      failed = []
      @channel.converted_feeds( @channel.link, @channel.rights ).each do |program_entry|
        unless link_or_create_venues(program_entry)
          Rails.logger.info "not all venues could be found or created for #{program_entry.title}"
          failed << program_entry
          next
        end
        unless download_images(program_entry)
          Rails.logger.info "downloading images failed for #{program_entry.title}"
          failed << program_entry
          next
        end
        if program_entry.save
          ok << program_entry
        else
          failed << program_entry
        end
      end
      render json: { ok: ok, failed: failed }
    end

    def update
      @syncer = Iox::Syncer.find_by_id params[:id]
      if @syncer.update syncer_params
        flash[:notice] = t 'syncer.saved', name: @syncer.name
        redirect_to syncers_path
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
        render template: 'new'
      end
    end

    private

    def syncer_params
      params.require(:syncer).permit(
        %w( name cron_line url festival_id )
      )
    end

    def link_or_create_venues(program_entry)
      failed = 0
      program_entry.events.each do |event|
        event.festival_id = @syncer.festival_id unless @syncer.festival_id.blank?
        event.save
        puts "festival #{event.festival}"
        next unless (event.venue && event.venue.new_record?)
        if venue = Venue.find_by_sync_id( event.venue.sync_id )
          event.venue = venue
          next
        end
        venues = Venue.find_by_name( event.venue.name ).all
        if venues.size == 1
          event.venue = venues.first
          next
        elsif venues.size == 0
          event.venue.save
          next
        end
        failed += 1
      end
      failed == 0
    end

    def download_images( program_entry )
      failed = 0
      program_entry.images.each do |image|
        next unless image.orig_url
        extname = File.extname( image.orig_url )
        basename = File.basename( image.orig_url, extname)
        file = Tempfile.new([basename, extname])
        file.binmode
        open( image.orig_url ) do |data|
          file.write data.read
        end
        file.rewind

        image.file = file
        unless image.save
          failed += 1
        end
      end
      failed == 0
    end

  end
end
