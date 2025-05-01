namespace :iox do
  namespace :instagram do

    desc "refresh instagram access token"
    task :refresh_token => :environment do
      instagram_helper = Iox::InstagramHelper.new()
      instagram_helper.refresh_access_token
    end
        
    desc "post media on instagram"
    task :post_on_instagram => :environment do
      logger = Logger.new("#{Rails.root}/log/instagram.log")
      instagram_helper = Iox::InstagramHelper.new()
      start = Time.now

      @program_events = Iox::ProgramEvent.postable_on_instagram.max_one_month.order(:starts_at)
      logger.info "Start instagram posts #(#{@program_events.count})"
      @program_events.each do |event|
        instagram_post = Iox::InstagramPost.new(program_entry_id: event.program_entry_id, program_event_id: event.id)
        caption = get_caption event
        image_url = "https://" + Rails.configuration.iox.domain_name + event.program_entry.images.first.file.url(:original)
        # for development usage
        # image_url = "https://theaterspielplan.at/data/avatars/4288301063264bfe824119328a864ba21895d653.jpg";
        logger.info image_url
        if ig_container_id = instagram_helper.create_media_container(caption, image_url)
          instagram_post.update(:ig_container_id => ig_container_id, :status => 1)
          # since instagram needs some time to process the container we wait and check status before we proceed
          sleep(5.seconds)
          if status = instagram_helper.container_status(ig_container_id)
            if status == 'FINISHED'
              if ig_media_response = instagram_helper.publish_media(ig_container_id)
                instagram_post.update(:ig_media_id => ig_media_response["id"], :shortcode => ig_media_response["shortcode"], :status => 2)
              end
            else
              logger.error "Container ID (#{ig_container_id}) is not available. Status: #{status}"
            end
          end
        end
      end
      logger.info "Finish instagram posts within #{(Time.now - start).to_i} seconds"
    end

    task :container_status, [:ig_container_id] => [:environment] do |t, args|
      ig_container_id = args[:ig_container_id]
      instagram_helper = Iox::InstagramHelper.new()
      puts instagram_helper.container_status(ig_container_id)
    end

    desc "publish media on instagram by given ig container id"
    task :publish_media, [:ig_container_id] => [:environment] do |t, args|
      ig_container_id = args[:ig_container_id]
      if instagram_post = Iox::InstagramPost.where(:ig_container_id => ig_container_id).where(:status => 1).first
        instagram_helper = Iox::InstagramHelper.new()
        if ig_media_response = instagram_helper.publish_media(ig_container_id)
          instagram_post.update(:ig_media_id => ig_media_response["id"], :shortcode => ig_media_response["shortcode"], :status => 2)
        end
      end
    end

    @new_line = "\n"
    @hr_line = @new_line + "――――――――――" + @new_line
    def get_caption(event)
      title = "PREMIERE" + @new_line
      title << "#{event.program_entry.cabaret_artist_names}: " if (event.program_entry.categories == 'kab' && event.program_entry.show_cabaret_artists_in_title) 
      title << event.program_entry.title
      caption = title
      caption << @hr_line
      caption << event.starts_at.strftime("%d.%m.%Y, %H:%M")
      caption << @hr_line
      caption << event.venue.name
      caption << @new_line
      caption << event.venue.street
      caption << "#{event.venue.zip}, #{event.venue.city}" if event.venue.zip && event.venue.city
      caption << @hr_line
      caption << Nokogiri::HTML(event.program_entry.description).text
      caption = caption[0..2000]
      caption << @hr_line
      caption << "Info @ theaterspielplan.at"
      caption
    end

  end
end