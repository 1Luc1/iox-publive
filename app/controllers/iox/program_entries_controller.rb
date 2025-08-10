module Iox
  class ProgramEntriesController < Iox::ApplicationController

    before_action :authenticate!
    layout 'iox/application'

    def index

      return unless request.xhr?

      @query = ''
      filter = (params[:filter] && params[:filter][:filters] && params[:filter][:filters]['0'] && params[:filter][:filters]['0'][:value]) || ''
      unless filter.blank?
        filter = filter.downcase
        if filter.match(/^[\d]*$/)
          @query = "iox_program_entries.import_foreign_db_id LIKE '#{filter}%' OR iox_program_entries.id =#{filter}"
        else
          if params[:only_venues] && params[:only_venues] == 'true'
            return search_by_venue_name(filter)
          else
            @query = "LOWER(title) LIKE '%#{filter}%' OR LOWER(subtitle) LIKE '%#{filter}%' OR LOWER(iox_program_entries.meta_keywords) LIKE '%#{filter}%'"
          end
        end
      end

      @only_mine = !params[:only_mine] || params[:only_mine] == 'true'
      @only_mine = true unless current_user.is_admin?

      @conflict = params[:conflict] && params[:conflict] == 'true'
      @future_only = params[:future_only] && params[:future_only] == 'true'
      @only_unpublished = params[:only_unpublished] && params[:only_unpublished] == 'true'
      @q = "only_mine=#{@only_mine}&future_only=#{@future_only}&only_unpublished=#{@only_unpublished}&query=#{filter}"
      if @future_only
        @query << " AND " if @query.size > 0
        @query << " iox_program_entries.ends_at >= '#{Time.now.strftime('%Y-%m-%d')}'"
      end
      if @only_mine
        @query << " AND " if @query.size > 0
        @query << " iox_program_entries.created_by = #{current_user.id}"
      end
      if @conflict
        @query << " AND " if @query.size > 0
        @query << " (iox_program_entries.conflict IS TRUE OR iox_program_entries.conflict_id IS NOT NULL)"
      end
      if @only_unpublished
        @query << " AND " if @query.size > 0
        @query << " iox_program_entries.published = false"
      end
      @user_query = ProgramEntry.where( @query )
      @user_query = ProgramEntry.where( @query ).where(created_by: current_user.id) unless current_user.is_admin?
      @total_items = @user_query.count
      @page = (params[:skip] || 0).to_i
      @page = @page / params[:pageSize].to_i if @page > 0 && params[:pageSize]
      @limit = (params[:take] || 20).to_i
      @total_pages = @total_items/@limit
      @total_pages += 1 if ((@total_items % @limit) > 0)

      @order = 'iox_program_entries.id'
      if params[:sort]
        sort = params[:sort]['0'][:field]
        unless sort.blank?
          sort = "iox_program_entries.#{sort}" if sort.match(/id|created_at|updated_at|starts_at|ends_at/)
          sort = "LOWER(title)" if sort === 'title'
          sort = "LOWER(iox_ensembles.name)" if sort == 'ensemble_name'
          sort = "LOWER(iox_users.username)" if sort == 'updater_name'
          @order = "#{sort} #{params[:sort]['0'][:dir]}"
        end
      end
      @user_query = ProgramEntry.where( @query )
      @user_query = ProgramEntry.where( @query ).where(created_by: current_user.id) unless current_user.is_admin?      
      @program_entries = @user_query.includes(:ensemble).includes(:updater).limit( @limit ).offset( (@page) * @limit ).order(@order).load.map do |pe|
        pe.venue_id = ''
        pe.venue_name = ''
        pe.ensemble_name = ''
        if pe.events.size > 0 && pe.events.first.venue
          pe.venue_id = pe.events.first.venue.id
          pe.venue_name = pe.events.first.venue.name
        end
        if pe.ensemble
          pe.ensemble_name = pe.ensemble.name
        end
        pe
      end

      render json: { items: @program_entries, total: @total_items, order: @order }

    end

    def new
      @program_entry = ProgramEntry.new duration: 90, categories: Rails.configuration.iox.publive_categories.first
      @layout = true
    end

    def settings_for
      check_404_and_privileges
      @obj = @program_entry
      render template: '/iox/program_entries/settings_for', layout: false
    end

    def find_conflicting_names
      @conflicts = ProgramEntry.where("LOWER(title) LIKE ? AND ends_at>?","%#{params[:title].downcase}%", Time.now)
      @conflicts = @conflicts.where("id != ?", params[:program_entry_id]) unless params[:program_entry_id].blank?
      render json: @conflicts.load
    end

    def create
      @program_entry = ProgramEntry.new entry_params
      @layout = true
      if current_user.is_admin? && params[:with_user]
        @program_entry.created_by = params[:with_user]
      else
        @program_entry.created_by = current_user.id
      end

      if @program_entry.save
        begin
          Iox::Activity.create! user_id: current_user.id, obj_name: @program_entry.title, action: 'created', icon_class: 'icon-calendar', obj_id: @program_entry.id, obj_type: @program_entry.class.name, obj_path: program_entries_path(@program_entry)
        rescue
        end

        flash.now.notice = t('program_entry.created')
        @proceed_to_step = 1
        render template: 'iox/program_entries/edit'
      else
        flash.now.alert = "#{t('program_entry.failed_to_save')}: #{@program_entry.errors.full_messages.join(' ').html_safe}"
        render template: 'iox/program_entries/new'
      end
    end

    def update
      if check_404_and_privileges
        @program_entry.updated_by = current_user.id

        if params[:with_user]
          @program_entry.created_by = params[:with_user]
        end

        @program_entry.attributes = entry_params
        
        if @program_entry.save

          Iox::Activity.create! user_id: current_user.id, obj_name: @program_entry.title, action: 'updated', icon_class: 'icon-calendar', obj_id: @program_entry.id, obj_type: @program_entry.class.name, obj_path: program_entries_path(@program_entry)

          flash.now.notice = t('program_entry.saved')
        else
          flash.now.alert = "#{t('program_entry.failed_to_save')}: #{@program_entry.errors.full_messages.join(' ').html_safe}"
        end
      else
        flash.now.alert = t('not_found')
      end
    end

    def finish
      if @program_entry = ProgramEntry.find_by_id( params[:id] )
        if @program_entry.update params.require(:program_entry).permit(:published, :others_can_change, :notify_me_on_change)
          flash.notice = t('program_entry.saved')
        else
          flash.alert = t('program_entry.failed_to_save')
        end
      else
        flash.alert = t('not_found')
      end
      redirect_to program_entries_path
    end

    #
    # publish a program_entry
    #
    def publish
      if check_404_and_privileges
        if params[:publish] == "true"
          @program_entry.published = true
        else
          @program_entry.published = false
        end
        if @program_entry.save
          @published = false
          if @program_entry.published?
            @published = true
            flash.now.notice = t('program_entry.has_been_published', name: @program_entry.title)
          else
            flash.now.notice = t('program_entry.has_been_unpublished', name: @program_entry.title)
          end

          Iox::Activity.create! user_id: current_user.id, obj_name: @program_entry.title, action: (@published ? 'published' : 'unpublished'), icon_class: 'icon-calendar', obj_id: @program_entry.id, obj_type: @program_entry.class.name, obj_path: program_entries_path(@program_entry)

        else
          flash.now.alert = 'unknown error'
        end
      end
      render :json => { flash: flash, item: @program_entry, success: !flash.notice.blank? }
    end

    def edit
      if @insufficient_rights = !check_404_and_privileges
        flash.now.alert = t('insufficient_rights_you_cannot_save')
      end
      @layout = (!params[:layout] || params[:layout] === 'true')
      render layout: @layout
    end

   def crew_of
      @program_entry = ProgramEntry.find_by_id( params[:id] )
      @crew = @program_entry.program_entry_people.includes(:person).references(:iox_people).order('iox_program_entry_people.position','iox_people.lastname','iox_people.firstname').load
      json_crew = []
      @crew.each do |person|
        unless person.person
          person.destroy
          next
        end
        json_crew << person
      end
      render json: json_crew
    end

    def events_for
      @program_entry = ProgramEntry.find_by_id( params[:id] )
      events = []
      @program_entries = @program_entry.events.includes(:venue,:festival)
                          .references(:iox_venues,:iox_program_entries)
                          .order('iox_program_events.starts_at')
                          .load
      json_pe = []
      @program_entries.each do |program_entry|
        if !program_entry.venue.nil?
          json_pe << program_entry
        end
      end
      render json: json_pe
    end

    def images_for
      if @program_entry = ProgramEntry.find_by_id( params[:id] )
        render json: @program_entry.images.map{ |i| i.to_jq_upload('file') }
      else
        logger.error "program entry not found (#{params[:id]})"
        render json: []
      end
    end

    def festivals
      @query = ''
      filter = (params[:filter] && params[:filter][:filters] && params[:filter][:filters]['0'] && params[:filter][:filters]['0'][:value]) || ''
      unless filter.blank?
        filter = filter.downcase
        @query = "LOWER(title) LIKE '%#{filter}%'"
      end
      @festivals = ProgramEntry.where(categories: 'fes').where( @query ).order(:title).load
      render json: @festivals
    end

    def upload_image
      if @program_entry = ProgramEntry.find_by_id( params[:id] )
        @image = @program_entry.images.build(
          name: (params[:name].blank? ? params[:image][:file].original_filename : params[:name]),
          description: params[:description],
          copyright: params[:copyright]
          )
        @image.file = params[:image][:file]
        if @image.save
          flash.notice = t('program_file.uploaded', name: @image.name )
          render :json => { item: @image.to_jq_upload('file'), flash: flash }
        else
          # don't think, this should be logged; since user gets information and can handle it
          logger.error "#{current_user.name} tried to upload #{@image.file.original_filename} #{@image.file.content_type}"
          render :json => {:errors => @image.errors}.to_json, :status => 500
        end
      else
        logger.error "program entry not found (#{params[:id]})"
      end
    end

    def download_image_from_url
      require 'uri'
      render( :json => {:errors => (@image ? @image.errors : 'image not found')}.to_json, :status => 500 ) if params[:download_url].blank?
      if @program_entry = ProgramEntry.find_by_id( params[:id] )
        extname = File.extname(params[:download_url])
        basename = File.basename(params[:download_url], extname)
        file = Tempfile.new([basename, extname])
        file.binmode
        d_url = params[:download_url];
        d_url = "http://#{d_url}" unless (d_url =~ /\A#{URI::regexp(['http', 'https'])}\z/)
        open( d_url ) do |data|
          file.write data.read
        end
        file.rewind

        @image = @program_entry.images.build(
          name: (params[:name].blank? ? basename : params[:name]),
          description: params[:description],
          copyright: params[:copyright]
          )
        @image.file = file
        if @image.save
          flash.notice = t('program_file.uploaded', name: @image.name )
          render :json => { item: @image.to_jq_upload('file'), flash: flash }
        else
          logger.info "ERROR: #{current_user.name} tried to upload #{basename} #{@image.errors.full_messages.inspect}"
          render :json => {:errors => @image.errors}.to_json, :status => 500
        end
      else
        logger.error "program entry not found (#{params[:id]})"
      end
    end

    def order_images
      if @program_entry = ProgramEntry.find_by_id( params[:id] )
        if params[:order]
          errors = 0
          params[:order].split(',').each_with_index do |img_id, pos|
            if @image = @program_entry.images.where( id: img_id.sub('image_','') ).first
              @image.position = pos
              errors += 1 unless @image.save
            else
              errors += 1
            end
          end
          if errors == 0
            flash.now.notice = t('program_file.order_saved')
          else
            flash.now.alert = t('program_file.order_failed')
          end
        end
      else
        flash.now.alert = t('not_found');
      end
      render json: flash
    end

    def order_crew
      if @program_entry = ProgramEntry.find_by_id( params[:id] )
        if params[:order]
          errors = 0
          params[:order].split(',').each_with_index do |crew_id, pos|
            @pe_person = @program_entry.program_entry_people.where( id: crew_id.sub('crew_','') ).first
            @pe_person.position = pos
            errors += 1 unless @pe_person.save
          end
          if errors == 0
            flash.now.notice = t('program_entry.order_saved')
          else
            flash.now.alert = t('program_entry.order_failed')
          end
        end
      else
        flash.now.alert = t('not_found');
      end
      render json: flash
    end

    def destroy
      if check_404_and_privileges
        if @program_entry.delete

        Iox::Activity.create! user_id: current_user.id, obj_name: @program_entry.title, action: 'deleted', icon_class: 'icon-calendar', obj_id: @program_entry.id, obj_type: @program_entry.class.name, obj_path: program_entries_path(@program_entry)

          flash.now.notice = t('program_entry.deleted', name: @program_entry.title, id: @program_entry.id )
        else
          flash.now.alert = t('program_entry.deletion_failed', name: @program_entry.title)
        end
      end
      render json: { success: !flash[:notice].blank?, flash: flash }
    end

    def restore
      if check_404_and_privileges
        if @program_entry.restore

          Iox::Activity.create! user_id: current_user.id, obj_name: @program_entry.title, action: 'restored', icon_class: 'icon-calendar', obj_id: @program_entry.id, obj_type: @program_entry.class.name, obj_path: program_entries_path(@program_entry)

          flash.now.notice = t('program_entry.restored', name: @program_entry.title)
        else
          flash.now.alert = t('program_entry.failed_to_restore', name: @program_entry.title)
        end
      end
    end

    private

    def entry_params
      params.require(:program_entry).permit([
        :queer, :feminism, :barrier_free, :diversity, 
        :fairpay, :green_event,:inklusion, :online_event,
        :talk, :sight, :hearing, :fairpay, :theatre,
        :dance, :performance, :music_theatre, :figures,
        :young_audience, :circus, :street_theatre,
        :new_media, :installation, :cabaret,
        :title, :subtitle,
        :description, :age,
        :duration, :ensemble_id,
        :categories, :url,
        :meta_keywords, 
        :meta_description,
        :author, :coproduction,
        :others_can_change,
        :published,
        :cabaret_artist_ids, 
        :author_ids,
        :youtube_url, :vimeo_url,
        :show_cabaret_artists_in_title, :has_breaks,
        :notify_me_on_change])
    end

    def redirect_if_no_rights
      if !current_user.is_admin?
        flash.alert = I18n.t('error.insufficient_rights')
        render json: { success: false, flash: flash }
        return false
      end
      true
    end

    def check_404_and_privileges(hard_check=false)
      @insufficient_rights = true
      unless @program_entry = ProgramEntry.unscoped.where( id: params[:id] ).first
        if request.xhr?
          flash.now.alert = t('not_found')
        else
          flash.alert = t('not_found')
          redirect_to ensembles_path
        end
        return false
      end

      if !current_user.is_admin? && @program_entry.created_by != current_user.id && (!@program_entry.others_can_change || hard_check)
        if request.xhr?
          flash.now.alert = t('insufficient_rights_you_cannot_save')
        else
          flash.alert = t('insufficient_rights_you_cannot_save')
          redirect_to ensembles_path
        end
        return false
      end
      @insufficient_rights = false
      true
    end

    def search_by_venue_name(filter)

      @only_mine = !params[:only_mine] || params[:only_mine] == 'true'

      @query = "LOWER(name) LIKE '%#{filter}%'"

      if @only_mine
        @query << " AND " if @query.size > 0
        @query << " created_by = #{current_user.id}"
      end

      matching_venue_ids = Venue.where( @query ).map do |venue|
        venue.id
      end

      if matching_venue_ids.size < 1
        return render json: { items: [], total: 0 }
      end

      clause = "iox_program_events.venue_id IN (#{matching_venue_ids.join(',')})"
      @total_items = ProgramEntry.joins(:events).where(clause).count
      @page = (params[:skip] || 0).to_i
      @page = @page / params[:pageSize].to_i if @page > 0 && params[:pageSize]
      @limit = (params[:take] || 20).to_i
      @total_pages = @total_items/@limit
      @total_pages += 1 if ((@total_items % @limit) > 0)

      @order = 'iox_program_entries.id'
      if params[:sort]
        sort = params[:sort]['0'][:field]
        unless sort.blank?
          sort = "iox_program_entries.#{sort}" if sort.match(/id|created_at|updated_at|starts_at|ends_at/)
          sort = "LOWER(title)" if sort === 'title'
          sort = "LOWER(iox_ensembles.name)" if sort == 'ensemble_name'
          sort = "LOWER(iox_users.username)" if sort == 'updater_name'
          @order = "#{sort} #{params[:sort]['0'][:dir]}"
        end
      end


      @program_entries = ProgramEntry.joins(:events).where(clause).limit( @limit ).offset( (@page) * @limit ).order(@order).map do |pe|
        pe.venue_id = ''
        pe.venue_name = ''
        pe.ensemble_name = ''
        if pe.events.size > 0 && pe.events.first.venue
          pe.venue_id = pe.events.first.venue.id
          pe.venue_name = pe.events.first.venue.name
        end
        if pe.ensemble
          pe.ensemble_name = pe.ensemble.name
        end
        pe
      end

      render json: { items: @program_entries, total: @total_items, order: @order }

    end


  end
end
