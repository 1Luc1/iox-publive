require "httparty"

module Iox
  class InstagramHelper

    @@logger = Logger.new("#{Rails.root}/log/instagram.log")

    include HTTParty
    base_uri 'https://graph.instagram.com'
 
    def initialize()
      if Settings.instagram_user_id.nil?
        options = {query: {access_token: Settings.instagram_access_token, fields: "user_id"}}
        response = self.class.get("/v22.0/me", options)
        Settings.instagram_user_id = response["user_id"]
      end
    end

    def access_token_escaped
      token = Settings.instagram_access_token
      "#{token.first(6)} ... #{token.last(6)}"
    end

    def access_token_expires_at
      ig_access_token = Settings.select("updated_at").where("var = 'instagram_access_token'").first
      ig_access_token["updated_at"] + 60.days
    end

    def refresh_access_token
        @@logger.info "refresh access token"
        options = {query: {access_token: Settings.instagram_access_token, grant_type: "ig_refresh_token"}}
        response = self.class.get("/refresh_access_token", options)
        Settings.instagram_access_token = response["access_token"]
    end

    def media_publish
      options = {query: {access_token: Settings.instagram_access_token}, body: JSON.generate({caption: "...", image_url:"https://theaterspielplan.at/data/avatars/4288301063264bfe824119328a864ba21895d653.jpg"}), headers: { 'Content-Type' => 'application/json' }}
      response = self.class.post("/v22.0/#{Settings.instagram_user_id}/media", options)
      ig_container_id = response["id"]
      
      options = {query: {access_token: Settings.instagram_access_token}, body: JSON.generate({creation_id: ig_container_id}), headers: { 'Content-Type' => 'application/json' }}
      response = self.class.post("/v22.0/#{Settings.instagram_user_id}/media_publish", options)
      ig_media_id = response["id"]
    end

    def content_publishing_current_usage
      options = {query: {access_token: Settings.instagram_access_token}}
      response = self.class.get("/v22.0/#{Settings.instagram_user_id}/content_publishing_limit", options)
      if response.code == 400
        "ERROR"
      else 
        response["data"][0]["quota_usage"]
      end
    end
  end
end
