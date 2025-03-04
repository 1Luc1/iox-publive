require_dependency "iox/application_controller"

module Iox
  class PeopleController < Iox::ApplicationController

    before_action :authenticate!, except: [ :show ]

    def index

      return unless request.xhr?

      @query = ''
      filter = (params[:filter] && params[:filter][:filters] && params[:filter][:filters]['0'] && params[:filter][:filters]['0'][:value]) || ''
      unless filter.blank?
        filter = filter.downcase
        if filter.match(/^[\d]*$/)
          @query = "iox_people.import_foreign_db_id LIKE '#{filter}%' OR iox_people.id =#{filter}"
        else
          @query = "LOWER(iox_people.firstname) LIKE '%#{filter}%' OR LOWER(iox_people.lastname) LIKE '%#{filter}%'"
        end
      end

      @only_mine = !params[:only_mine] || params[:only_mine] == 'true'
      if @only_mine
        @query << " AND " if @query.size > 0
        @query << " iox_people.created_by = #{current_user.id}"
      end

      @total_items = Person.where( @query ).count
      @page = (params[:skip] || 0).to_i
      @page = @page / params[:pageSize].to_i if @page > 0 && params[:pageSize]
      @limit = (params[:take] || 20).to_i
      @total_pages = @total_items/@limit
      @total_pages += 1 if ((@total_items % @limit) > 0)

      @order = 'iox_people.id'
      if params[:sort]
        sort = params[:sort]['0'][:field]
        unless sort.blank?
          sort = "iox_people.#{sort}" if sort.match(/id|created_at|updated_at|lastname|firstname/)
          sort = "LOWER(title)" if sort === 'title'
          sort = "LOWER(iox_ensembles.name)" if sort == 'ensemble_names'
          sort = "LOWER(iox_users.username)" if sort == 'updater_name'
          @order = "#{sort} #{params[:sort]['0'][:dir]}"
        end
      end

      @people = Person.where( @query ).includes(:ensembles).includes(:updater).references(:iox_ensembles, :iox_users).limit( @limit ).offset( (@page) * @limit ).order(@order).load

      render json: { items: @people, total: @total_items, order: @order }
    end

    def simple
      @query = Person
      filter = (params[:filter] && params[:filter][:filters] && params[:filter][:filters]['0'] && params[:filter][:filters]['0'][:value]) || ''
      unless filter.blank?
        filter = filter.downcase
        if filter.split(' ').size > 1
          @query = @query.where("firstname LIKE ? AND lastname LIKE ?", "%#{filter.split(' ').first}%", "%#{filter.split(' ').last}%" )
        else
          @query = @query.where("firstname LIKE ? OR lastname LIKE ?", "%#{filter}%", "%#{filter}%" )
        end
      end
      render json: @query.order('firstname,lastname').load, :simple => true
    end

    def new
      @person = Person.new name: (params[:name] || '')
      names = (params[:name] || '').split(' ')
      if names.size != 0
        @found = Person.where({})
        puts "names: #{names}"
        if names.size > 1
          @found = @found.where("firstname LIKE ?", "%#{names[0..-2].join(' ')}%")
        end
        if names.size > 0
          @found = @found.where("lastname LIKE ?", "%#{names.last}%")
        end
      end
      
      @help_txt = t('person.firstname_lastname')
      render template: 'iox/people/new_modal', layout: false
    end

    def create
      @person = Person.new person_params
      @person.created_by = @person.updated_by = current_user.id
      if @person.save

        Iox::Activity.create! user_id: current_user.id, obj_name: @person.name, action: 'created', icon_class: 'icon-group', obj_id: @person.id, obj_type: @person.class.name, obj_path: people_path(@person)

        flash.notice = t('person.saved', name: @person.name)
        if request.xhr?
          @remote = true
        else
          redirect_to edit_person_path( @person )
        end
      else
        flash.alert = "#{t('person.saving_failed', name: @person.name)}: #{@person.errors.full_messages.join(' ').html_safe}"
        unless request.xhr?
          render template: 'iox/people/new'
        end
      end
    end

    def show
      check_404_and_privileges
    end

    def edit
      check_404_and_privileges
      @layout = (!params[:layout] || params[:layout] === 'true')
      render layout: @layout
    end

    def settings_for
      check_404_and_privileges
      @obj = @person
      render template: '/iox/program_entries/settings_for', layout: false
    end

    def update
      if check_404_and_privileges
        @person.updater = current_user
        @person.attributes = person_params

        if params[:with_user]
          @person.created_by = params[:with_user]
        end

        if params[:person][:tags]
          @person.tag_ids = params[:person][:tags]
        end

        if @person.save

          begin
            Iox::Activity.create! user_id: current_user.id, obj_name: @person.name, action: 'updated', icon_class: 'icon-group', obj_id: @person.id, obj_type: @person.class.name, obj_path: people_path(@person)
          rescue
          end

          flash.notice = t('person.saved', name: @person.name)
          flash.notice = t('settings_saved', name: @person.name) if params[:settings_form]
          unless request.xhr?
            redirect_to edit_person_path( @person )
          end
        else
          flash.alert = "#{t('person.saving_failed', name: @person.name)}: #{@person.errors.full_messages.join(' ').html_safe}"
          flash.alert = t('settings_saving_failed', name: @person.name) if params[:settings_form]
          unless request.xhr?
            render template: 'iox/people/edit'
          end
        end
      else
        unless request.xhr?
          redirect_to people_path
        end
      end
    end

    #
    # upload avatar
    #
    def upload_avatar
      if check_404_and_privileges
        @person.avatar = params[:person][:avatar]
        if @person.save
          render :json => [@person.to_jq_upload('avatar')].to_json
        else
          render :json => [{:error => "custom_failure"}], :status => 304
        end
      else
        render :json => [{:error => 'not found'}], :status => 404
      end
    end

    def upload_pictures
    end

    def destroy
      if check_404_and_privileges true
        if @person.delete

          Iox::Activity.create! user_id: current_user.id, obj_name: @person.name, action: 'deleted', icon_class: 'icon-group', obj_id: @person.id, obj_type: @person.class.name, obj_path: people_path(@person)

          flash.now.notice = t('person.deleted', name: @person.name, id: @person.id)
        else
          flash.now.alert = t('person.deletion_failed', name: @person.name)
        end
      end
      render json: { success: !flash[:notice].blank?, flash: flash }
    end

    def restore
      if check_404_and_privileges

        if @person.restore

          Iox::Activity.create! user_id: current_user.id, obj_name: @person.name, action: 'restored', icon_class: 'icon-user', obj_id: @person.id, obj_type: @person.class.name, obj_path: person_path(@person)

          flash.now.notice = t('person.restored', name: @person.name)
        else
          flash.now.alert = t('person.failed_to_restore', name: @person.name)
        end
      end
    end

    def merge
      return unless is_admin
      @people = Person.select("firstname, lastname, count(firstname) AS cnt, GROUP_CONCAT(email SEPARATOR ', ') as concat_email, GROUP_CONCAT(id) as ids")
                      .group("firstname, lastname")
                      .having("cnt > 1")
                      .load
      render layout: true
    end

    def clean
      return unless is_admin
      # ONLY CHECK DIRECT RELETAIONS! since using via table isn't correct
      #   @people = Person.reflect_on_all_associations().map(&:name)
      #   [:program_entry_people, :program_entries, :ensemble_people, :ensembles, :taggings, :tags, :creator, :updater, :images] 
      # ONLY check iox_program_entry_people and iox_ensemble_people

      @people = Person.select("iox_people.id, firstname, lastname").left_outer_joins( :program_entry_people, :ensemble_people)
      .where(iox_program_entry_people: { id: nil })
      .where(iox_ensemble_people: { id: nil })
      .where(email: [nil, ''])

      @cleaned_people = Person.unscoped.where("time(deleted_at) = '00:00:00'")

      render layout: true
    end

    def clean_selected
      return unless is_admin
      if !params[:ids]
        @nothing_selected = true
        flash.notice = t('program_entry_person.no_person_given')
      else
        params[:ids].each do |id|
          person = Person.find(id)
          person.clean
        end unless params[:ids].blank?
        flash.notice = t('people.deleted', cnt: params[:ids].count)
      end
      redirect_to clean_people_path
    end
    


    private

    def check_404_and_privileges(hard_check=false)
      @insufficient_rights = true
      unless @person = Person.unscoped.where( id: params[:id] ).first
        flash.now.alert = t('not_found')
        return false
      end
      if !current_user.is_admin? && @person.created_by != current_user.id && (!@person.others_can_change || hard_check)
        flash.now.alert = t('insufficient_rights_you_cannot_save')
        return false
      end
      @insufficient_rights = false
      true
    end

    def is_admin
      if !current_user.is_admin?
        @insufficient_rights = true
        flash.now.alert = t('insufficient_rights')
        return false
      end
      return true
    end

    def person_params
      params.require(:person).permit([:email, :firstname, :lastname, :url, :city, :zip, :description, :name, :others_can_change, :notify_me_on_change])
    end

  end
end
