module Iox
  class SyncLog < ActiveRecord::Base
    
    belongs_to :syncer

    attr_accessor :failed_entries, :ok_entries

  end
end
