module Iox
  module ProgramEntriesHelper

    def get_ensembles
      Ensemble.order("name ASC").load.map{ |e| [ "#{e.name}", e.id ] }
    end

    def get_people
      Person.order("lastname, firstname").load.map{ |p| [ "#{p.firstname} #{p.lastname}", p.id ] }
    end

    def get_venues
      Venue.order("name").load.map{ |v| [ "#{v.name}", v.id ] }
    end

    def get_fes
      ProgramEntry.where(categories: 'fes').where("ends_at >= ?", Time.now).order(:title,:subtitle).load.map{ |f| [ "<p><strong>#{f.title}</strong><br/>#{f.subtitle.blank? ? '' : "#{f.subtitle}<br/>"}<em>#{l f.starts_at unless f.ends_at.blank?} &mdash; #{l f.ends_at unless f.ends_at.blank?}</p>", f.id] }
    end

    def get_reductions
      Rails.configuration.iox.publive_reductions
    end

    def get_clean_categories
      Rails.configuration.iox.publive_categories.reject{ |c| c == 'all' }
    end

  end
end