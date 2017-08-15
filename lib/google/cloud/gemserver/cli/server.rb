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
require "fileutils"
require "yaml"
require "open3"

module Google
  module Cloud
    module Gemserver
      class CLI

        ##
        # # Server
        #
        # Object responsible for deploying the gemserver to Google Cloud
        # Platform and starting it.
        #
        class Server

          ##
          # The Configuration object used to deploy the gemserver
          # @return [Configuration]
          attr_reader :config

          ##
          # Creates a Server instance by initializing a Configuration object
          # that will be used to access paths to necessary configuration files.
          def initialize
            ensure_gcloud_beta!
            @config = Configuration.new
          end

          ##
          # Starts the gemserver by starting up the gemstash server with
          # predefined options.
          def start
            path = if ENV["APP_ENV"] == "production"
                     Configuration::GAE_PATH
                   else
                     @config.config_path
                   end
            args = [
              "start",
              "--no-daemonize",
              "--config-file=#{path}"
            ].freeze
            Google::Cloud::Gemserver::Backend::StorageSync.download_service
            Google::Cloud::Gemserver::Backend::GemstashServer.start args
          end

          ##
          # Deploys the gemserver to Google Cloud Platform if the app
          # environment variable is set to "production." Otherwise, the
          # gemserver is started locally.
          def deploy
            return start if ["test", "dev"].include? ENV["APP_ENV"]
            begin
              puts "Beginning gemserver deployment..."
              base_deploy
              setup_default_keys
            ensure
              cleanup
            end
          end

          ##
          # Updates the gemserver on a Google Cloud Platform project by
          # redeploying it if Google App Engine is the target platform or by
          # updating the container image if Google Container image is the target
          # platform.
          def update
            return unless @config.deployed?

            puts "Updating gemserver..."

            if @config.metadata[:platform] == "gke"
              begin
                prepare_dir
                Google::Cloud::Gemserver::Deployer.new.update_gke_deploy
              ensure
                cleanup
              end
            else
              base_deploy
            end
          end

          ##
          # Deletes a given gemserver and its Cloud SQL instance
          #
          # @param [String] proj_id The project ID of the project the gemserver
          # was deployed to.
          def delete proj_id
            return unless @config.deployed?
            if @config.metadata[:platform] == "gae"
              full_delete = user_input("This will delete the entire Google Cloud"\
                " Platform project #{proj_id}. Continue"\
                " deletion? (Y|n, default n) If no, all relevant resources will"\
                " be deleted besides the parent GCP project.").downcase
              if full_delete == "y"
                puts "Deleting gemserver with parent project"
                system "gcloud projects delete #{proj_id}"
              else
                @config.delete_from_cloud
                del_gcs_files
                puts "Visit:\n https://console.cloud.google.com/appengine/"\
                  "settings?project=#{proj_id} and click \"Disable "\
                  " Application\" to delete the Google App Engine application"\
                  " the gemserver was deployed to."
              end
            else
              name = user_input "Enter the name of the container cluster"
              zone = user_input "Enter the zone of the cluster"
              system "kubectl delete service #{Deployer::IMAGE_NAME}"
              system "kubectl delete deployment #{Deployer::IMAGE_NAME}"
              system "gcloud container clusters delete #{name} -z #{zone}"
            end

            inst = @config.app["beta_settings"]["cloud_sql_instances"]
              .split(":").pop
            puts "Deleting child Cloud SQL instance #{inst}..."
            params = "delete #{inst} --project #{proj_id}"
            status = system "gcloud beta sql instances #{params}"
            fail "Unable to delete instance" unless status
          end

          private

          ##
          # @private Deploys the gemserver to Google Cloud Platform, waits for
          # it to be accessible, then saves its configuration and displays
          # next steps.
          def base_deploy
            prepare_dir
            Google::Cloud::Gemserver::Deployer.new.deploy
            wait_until_server_accessible
            @config.save_to_cloud
            display_next_steps
          end

          ##
          # @private Deletes all gem data files on Google Cloud Storage.
          def del_gcs_files
            # TODO: differentiate between GAE/GKE gem files, use gemstash's base_path option
            puts "Deleting all gem data on Google Cloud Storage..."
            gem_files = GCS.files Configuration::GEMSTASH_DIR
            gem_files.each { |f| f.delete }
          end

          ##
          # @private Creates a key with all permissions and sets it in the
          # necessary configurations (gem credentials and bundle config).
          def setup_default_keys
            should_create = user_input("Would you like to setup a default " \
              "key? [Y/n] (default yes)")
            return if should_create.downcase == "n"
            gemserver_url = remote
            res = Request.new(gemserver_url).create_key
            abort "Error generating key" unless res.code.to_i == 200
            key = Backend::Key.send :parse_key, res.body
            abort "Invalid key" unless valid_key? key
            puts "Generated key: #{key}"
            set_bundle key, gemserver_url
            set_gem_credentials key
          end

          ##
          # @private Sets a given key in the bundle config used by bundler for
          # installing gems.
          #
          # @param [String] key The key to be added to the bundle config.
          # @param [String] gemserver_url The URL of the gemserver.
          def set_bundle key, gemserver_url
            puts "Updating bundle config"
            run_cmd "bundle config http://#{gemserver_url}/private #{key}"
          end

          ##
          # @private Sets a given key in the gem credentials file used by
          # Rubygems.org
          #
          # @param [String] key The key to be added to the credentials.
          def set_gem_credentials key
            key_name = sanitize_name(user_input("Updating bundle config. Enter"\
              " a name for your key (default is \"master-gemserver-key\""))
            key_name = key_name.empty? == true ? Configuration::DEFAULT_KEY_NAME : key_name
            puts "Updating #{Configuration::CREDS_PATH}"

            FileUtils.touch Configuration::CREDS_PATH
            keys = YAML.load_file(Configuration::CREDS_PATH) || {}

            if keys[key_name.to_sym].nil?
              system "echo \":#{key_name}: #{key}\" >> #{Configuration::CREDS_PATH}"
            else
              puts "The key name \"#{key_name}\" already exists. Please update"\
                " #{Configuration::CREDS_PATH} manually to replace the key or" \
                " manually enter a different name into the file for your key:" \
                " #{key}."
            end
          end

          ##
          # @private Checks if a key is valid by its length and value.
          #
          # @param [String] key The key to be validated.
          #
          # @return [Boolean]
          def valid_key? key
            size = key.size == Backend::Key::KEY_LENGTH
            m_size = key.gsub(/[^0-9a-z]/i, "").size == Backend::Key::KEY_LENGTH
            size && m_size
          end

          ##
          # @private Sanitizes a name by removing special symbols and ensuring
          # it is alphanumeric (and hyphens, underscores).
          #
          # @param [String] name The name to be sanitized.
          #
          # @return [String]
          def sanitize_name name
            name = name.chomp
            name.gsub(/[^0-9a-z\-\_]/i, "")
          end

          ##
          # @private Outputs helpful information to the console indicating the
          # URL the gemserver is running at and how to use the gemserver.
          def display_next_steps
            puts "\nThe gemserver has been deployed! It is running on #{remote}"
            puts "\nTo see the status of the gemserver, visit: \n" \
              " #{remote}/health"
            puts "\nTo see how to use your gemserver to push and download " \
              "gems read https://github.com/GoogleCloudPlatform/google-cloud-" \
              "gemserver/blob/master/docs/usage_example.md for some examples."
            puts "\nFor general information, visit https://github.com/" \
              "GoogleCloudPlatform/google-cloud-gemserver/blob/master/README.md"
          end

          ##
          # @private Pings the gemserver until a timeout or the gemserver
          # replies with a 200 response code.
          #
          # @param [Integer] timeout The length of time the gemserver is
          # pinged. Optional.
          def wait_until_server_accessible timeout = 90
            puts "Waiting for the gemserver to be accessible..."
            start_time = Time.now
            url = remote
            loop do
              if Time.now - start_time > timeout
                fail "Could not establish a connection to the gemserver"
              else
                if url == "<pending>"
                  url = remote
                  next
                end
                r = Request.new(url).health
                break if r.code.to_i == 200
              end
              sleep 2
            end
          end

          ##
          # @private The URL of the gemserver.
          #
          # @return [String]
          def remote
            if @config.metadata[:platform] == "gke"
              info = run_cmd("kubectl get service #{Deployer::IMAGE_NAME}")
              info.split("\n").drop(1)[0].split[2]
            else
              flag = "--project #{@config[:proj_id]}"
              descrip = YAML.load(run_cmd "gcloud app describe #{flag}")
              descrip["defaultHostname"]
            end
          end

          ##
          # @private The Gemfile used by the gemserver on Google App Engine.
          #
          # @return [String]
          def gemfile_source
            <<~SOURCE
              source "https://rubygems.org"

              gem "google-cloud-gemserver", "#{Google::Cloud::Gemserver::VERSION}", path: "."
              gem "concurrent-ruby", require: "concurrent"
              gem "gemstash", "~> 1.1.0"
              gem "mysql2", "~> 0.4"
              gem "filelock", "~> 1.1.1"
              gem "google-cloud-storage", "~> 1.1.0"
              gem "google-cloud-resource_manager", "~> 0.24"
              gem "activesupport", "~> 4.2"
            SOURCE
          end

          ##
          # @private Creates a Gemfile and Gemfile.lock for the gemserver that
          # runs on Google App Engine such that gemstash is not required
          # client side for the CLI.
          def gemfile
            File.open("#{Configuration::SERVER_PATH}/Gemfile", "w") do |f|
              f.write gemfile_source
            end

            require "bundler"
            Bundler.with_clean_env do
              run_cmd "cd #{Configuration::SERVER_PATH} && bundle lock"
            end
          end

          ##
          # @private Creates a temporary directory with the necessary files to
          # deploy the gemserver.
          def prepare_dir
            dir = Gem::Specification.find_by_name(Configuration::GEM_NAME).gem_dir
            cleanup if Dir.exist? Configuration::SERVER_PATH
            FileUtils.mkpath Configuration::SERVER_PATH
            FileUtils.cp_r "#{dir}/.", Configuration::SERVER_PATH
            FileUtils.cp @config.config_path, Configuration::SERVER_PATH
            gemfile
            return unless @config.metadata[:platform] == "gae"
            FileUtils.cp @config.app_path, Configuration::SERVER_PATH
          end

          ##
          # @private Deletes the temporary directory containing the files used
          # to deploy the gemserver.
          def cleanup
            FileUtils.rm_rf Configuration::SERVER_PATH
          end

          ##
          # @private Runs a given command on the local machine.
          #
          # @param [String] args The command to be run.
          def run_cmd args
            `#{args}`
          end

          ##
          # @private Gets input from the user after displaying a message.
          #
          # @param [String] msg The message to be displayed.
          #
          # @return [String]
          def user_input msg
            puts msg
            STDIN.gets.chomp
          end

          ##
          # @private Ensure the gcloud SDK beta component is installed.
          def ensure_gcloud_beta!
            Open3.capture3 "yes | gcloud beta --help"
            nil
          end

          ##
          # @private Display a prompt and get user input.
          #
          # @param [String] prompt The prompt displayed to the user.
          #
          # @return [String]
          def user_input prompt
            puts prompt
            STDIN.gets.chomp
          end
        end
      end
    end
  end
end
