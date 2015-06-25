module Iox

  module SyncersHelper

    def sync_now syncer
      start = Time.now
      @syncer = syncer
      @sync_error_log = []
      require Rails.root.join("lib/tsp/parsers/ess/ess")
      return unless @channel = ESS.parse_file( @syncer.url ).first
      ok = []
      failed = []
      @channel.converted_feeds( @channel.link, @channel.rights, syncer.user ).each do |program_entry|
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
      @sync_error_log << "completed successfully" if @sync_error_log.size < 1
      sync_log = @syncer.sync_logs.create seconds_ran: (Time.now - start).to_i, message: @sync_error_log.join('<br>'), ok: ok.size, failed: failed.size, failed_entries: failed, ok_entries: ok
    end

    private

    def link_or_create_venues(program_entry)
      failed = 0
      program_entry.events.each do |event|
        event.festival_id = @syncer.festival_id unless @syncer.festival_id.blank?
        unless event.save
          @sync_error_log << "#{program_entry.id} (#{program_entry.title}): Failed to save event #{event.id}"
        end
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
          unless event.venue.save
            @sync_error_log << "#{program_entry.id} (#{program_entry.title}): Failed to save venue #{event.venue.id} (#{event.venue.title})"
          end
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
        begin
          file = Tempfile.new([basename, extname])
          file.binmode
          open( image.orig_url ) do |data|
            file.write data.read
          end
          file.rewind

          image.file = file
          unless image.save
            @sync_error_log << "#{program_entry.id} (#{program_entry.title}): Failed to save (unknown reason)"
            failed += 1
          end
        rescue OpenURI::HTTPError
          @sync_error_log << "#{program_entry.id} (#{program_entry.title}): Failed to download image: #{image.orig_url}. Image removed"
          image.destroy
          failed += 1
        rescue URI::InvalidURIError
          @sync_error_log << "#{program_entry.id} (#{program_entry.title}): URL not accepted: #{image.orig_url}. Image removed"
          image.destroy
          failed += 1
        end
      end
      failed == 0
    end
  end

end
