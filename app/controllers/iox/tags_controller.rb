require_dependency "iox/application_controller"

module Iox
  class TagsController < Iox::ApplicationController

    before_action :authenticate!

    def simple
      tags = Tag.order('id,name').load
      aryTags = tags.to_ary
      aryTags.push({"id":147,"name":"Andere"})
      render json: aryTags, only: [:id, :name]
    end

  end
end
