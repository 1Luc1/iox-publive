require "rails-settings-cached"
module Iox
  class Settings < RailsSettings::Base
    cache_prefix { "v1" }
    self.table_name = "iox_settings"

    field :instagram_access_token, type: :string
    field :instagram_user_id, type: :string
  end
end
