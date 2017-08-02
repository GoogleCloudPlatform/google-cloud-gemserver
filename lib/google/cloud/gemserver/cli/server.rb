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
            begin
              return start if ["test", "dev"].include? ENV["APP_ENV"]
              prepare_dir
              puts "Beginning gemserver deployment..."
              path = "#{Configuration::SERVER_PATH}/app.yaml"
              flags = "-q --project #{@config[:proj_id]}"
              status = system "gcloud app deploy #{path} #{flags}"
              fail "Gemserver deployment failed. " unless status
              @config.save_to_cloud
              setup_default_keys
              display_next_steps
            ensure
              cleanup
            end
          end

          ##
          # Updates the gemserver on a Google Cloud Platform project by
          # redeploying it.
          def update
            return unless Configuration.deployed?
            puts "Updating gemserver..."
            deploy
          end

          ##
          # Deletes a given gemserver by its parent project's ID.
          #
          # @param [String] proj_id The project ID of the project the gemserver
          # was deployed to.
          def delete proj_id
            puts "Deleting gemserver with parent project"
            @config.delete_from_cloud
            run_cmd "gcloud projects delete #{proj_id}"
          end

          private

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
              "a name for your key (default is \"master-gemserver-key\""))
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
            puts "The gemserver has been deployed! It is running on #{remote}"
            puts "To see how to use your gemserver to push and download gems" \
              "read https://github.com/GoogleCloudPlatform/google-cloud-" \
              "gemserver/blob/master/docs/usage_example.md for some examples."
            puts "For general information, visit https://github.com/" \
              "GoogleCloudPlatform/google-cloud-gemserver/blob/master/README.md"
          end

          ##
          # @private The URL of the gemserver.
          #
          # @return [String]
          def remote
            flag = "--project #{@config[:proj_id]}"
            descrip = YAML.load(run_cmd "gcloud app describe #{flag}")
            descrip["defaultHostname"]
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
              gem "gemstash", git: "https://github.com/bundler/gemstash.git", ref: "a5a78e2"
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
            FileUtils.cp @config.app_path, Configuration::SERVER_PATH
            gemfile
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
        end
      end
    end
  end
end
