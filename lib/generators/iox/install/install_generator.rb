require 'rails/generators/migration'

module Iox
  module Generators
    class InstallGenerator < Rails::Generators::Base

      source_root File.expand_path('../templates', __FILE__)

      desc "Installs TASTENbOX into your application"

      def setup_and_create

        directory "leafletjs", "public/leafletjs"

      end

    end
  end
end
