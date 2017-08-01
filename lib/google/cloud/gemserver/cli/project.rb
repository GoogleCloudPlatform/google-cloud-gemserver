# Copyright 2017 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "google/cloud/gemserver"
require "google/cloud/resource_manager"
require "securerandom"

module Google
  module Cloud
    module Gemserver
      class CLI
        ##
        # # Project
        #
        # Holds a reference to a project on Google Cloud Platform.
        #
        class Project

          ##
          # The name of the project on Google Cloud platform; same as ID.
          # @return [String]
          attr_accessor :proj_name

          ##
          # The Configuration object storing the settings used by the Project
          # object.
          # @return [Configuration]
          attr_accessor :config

          ##
          # Initializes the project name and Configuration object.
          def initialize name = nil
            @proj_name = name
            @config = Configuration.new
          end

          ##
          # Fetches a reference to the given project on Google Cloud Platform
          # and prompts the user to configure it correctly.
          def create
            raise "Project name was not provided!" unless @proj_name
            begin
              @config.update_config @proj_name, :proj_id
              create_gae_project
              enable_api
              enable_billing
              project
            rescue Google::Cloud::PermissionDeniedError, RuntimeError => e
              puts "Permission denied. You might not be authorized with " \
                "gcloud. Read github.com/GoogleCloudPlatform/google-cloud`." \
                "-ruby/google-cloud-gemserver/docs/authentication.md for " \
                "more information on how to get authenticated."
              puts "If you still get this error the Cloud Resource Manager " \
                "API might not be enabled."
              abort "More details: #{e.message}"
            end
          end

          private

          ##
          # @private Checks if the current Google Cloud Platform project
          # contains a Google App Engine project. If not, one is created.
          def create_gae_project
            return if project_exists?
            puts "Required Google App Engine project does not exist."
            system "gcloud app create --project #{@proj_name}"
          end

          ##
          # @private Checks if a Google App Engine project exists.
          #
          # @return [Boolean]
          def project_exists?
            system "gcloud app describe --project #{@proj_name} >/dev/null 2>&1"
          end

          ##
          # @private Prompts the user to press enter.
          #
          # @return [String]
          def prompt_user
            STDIN.gets
          end

          ##
          # @private Fetches a given project on Google Cloud Platform.
          #
          # @return [Google::Cloud::ResourceManager::Project]
          def project
            resource_manager = Google::Cloud::ResourceManager.new
            resource_manager.project @proj_name
          end

          ##
          # @private Prompts the user to enable necessary APIs for the
          # gemserver to work as intended.
          #
          # @return [String]
          def enable_api
            puts "Enable the Google Cloud SQL API if it is not already "\
              "enabled by visiting: https://console.developers.google.com"\
              "/apis/api/sqladmin.googleapis.com/overview?project=#{@proj_name}"\
              " and clicking \"Enable\""
            puts "Enable the Google Cloud Resource manager API if it is not already "\
              "enabled by visiting: https://console.developers.google.com"\
              "/apis/api/cloudresourcemanager.googleapis.com/overview?project=#{@proj_name}"\
              " and clicking \"Enable\""
            puts "Enable the Google App Engine Admin API if it is not already "\
              "enabled by visiting: https://console.developers.google.com"\
              "/apis/api/appengine.googleapis.com/overview?project=#{@proj_name}"\
              " and clicking \"Enable\""
            puts "Press Enter after enabling the APIs to continue"
            prompt_user
          end

          ##
          # @private Prompts the user to enable billing such that the gemserver
          # work as intended.
          #
          # @return [String]
          def enable_billing
            puts "Enable billing for the project you just created by "\
              "visiting the Google Cloud Platform console and selecting "\
              "your new project."
            puts "Press Enter after doing so to continue"
            prompt_user
          end
        end
      end
    end
  end
end
