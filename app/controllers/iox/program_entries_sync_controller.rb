module Iox
  class ProgramEntriesSyncController < Iox::ApplicationController

    before_filter :authenticate!
    layout 'iox/application'

  end
end
