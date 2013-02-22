require 'generators/common'

module Batman
  module Generators
    class AppGenerator < ::Rails::Generators::Base
      include Common
      requires_app_name

      desc "This generator installs Batman.js with a default folder layout"

      class_option :skip_git, :type => :boolean, :aliases => "-G", :default => false,
                              :desc => "Skip Git ignores and keeps"

      class_option :skip_jquery, :type => :boolean, :aliases => "-J", :default => false,
                              :desc => "Skip including jQuery"

      class_option :skip_es5, :type => :boolean, :default => false,
                              :desc => "Skip including the ES5 shim"

      def setup_rails
        with_app_name do
          template "rails/controller.rb", "app/controllers/#{app_name}_controller.rb"
          template "rails/layout.html", "app/views/layouts/#{app_name}.html.erb"

          unless ENV["RAILS_ENV"] == "test"
            inject_into_file "config/routes.rb", :after => "#{js_application_name}::Application.routes.draw do\n"  do
              route_catchall
            end
          end

        end
      end

      def create_app
        with_app_name do
          template "batman/batman_app.coffee", "#{app_path}/#{application_name}.js.coffee"
        end
      end

      def create_directories
        %w(models views controllers html lib).each do |dir|
          empty_directory "#{app_path}/#{dir}"
          create_file "#{app_path}/#{dir}/.gitkeep" unless options[:skip_git]
        end
      end

      def create_default_controllers
        with_app_name do
          empty_directory "#{app_path}/html/main"

          template "batman/application_controller.coffee", "#{app_path}/controllers/application_controller.js.coffee"
          template "batman/main_controller.coffee", "#{app_path}/controllers/main_controller.js.coffee"
          template "batman/html/main_index.html", "#{app_path}/html/main/index.html"
        end
      end

      def inject_batman
        with_app_name do
          application_file = File.join(app_path, "#{application_name}.js.coffee")

          prepend_file application_file, ES5_REQUIRES unless options[:skip_es5]
          prepend_file application_file, BATMAN_REQUIRES
          prepend_file application_file, JQUERY_REQUIRES unless options[:skip_jquery]
          prepend_file application_file, APP_REQUIRES
        end
      end

      private

      def file_exists?(file)
        relative_root = relative_to_original_destination_root(destination_root, false)
        source_paths.any? do |source|
          source_file = File.expand_path(file, File.join(source, relative_root))
          File.exists?(source_file)
        end
      end

      def route_catchall
# \n  match ":controller(/:action(/:id))", to: "#{app_name}\#index", :constraints => { :format => 'html' }\n
<<-CODE
\n  match "(/*redirect_path)", to: "#{app_name}\#index", :constraints => { :format => 'html' }\n
CODE
      end

ES5_REQUIRES = <<-CODE
#= require batman/es5-shim\n
CODE

BATMAN_REQUIRES = <<-CODE
#= require batman/batman
#= require batman/batman.rails\n
CODE

JQUERY_REQUIRES = <<-CODE
#= require jquery
#= require batman/batman.jquery\n
CODE

APP_REQUIRES = <<-CODE
#= require_self

#= require_tree ./controllers
#= require_tree ./models
#= require_tree ./views
#= require_tree ./lib\n
CODE
      end
    end
  end
end