namespace :iox do
  namespace :instagram do

    desc "refresh instagram access token"
    task :refresh_token => :environment do
      instagram_helper = Iox::InstagramHelper.new()
      instagram_helper.refresh_access_token
    end

  end
end