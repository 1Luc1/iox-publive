module Iox
  class ProgramEntriesSyncController < Iox::ApplicationController

    before_action :authenticate!
    layout 'iox/application'

  end
end
