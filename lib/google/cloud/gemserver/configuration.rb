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

require "fileutils"
require "yaml"
require "active_support/core_ext/hash/deep_merge"

module Google
  module Cloud
    module Gemserver
      ##
      #
      # # Configuration
      #
      # Stores configurations for the gemserver and provides methods for
      # altering that configuration.
      #
      class Configuration
        ##
        # Default configuration settings for the production database.
        PROD_DB_DEFAULTS = {
            database: "mygems",
            username: "test",
            password: "test",
            host: "localhost",
            socket: "# this will be set automatically"
        }.freeze

        ##
        # Default configuration settings for the dev database.
        DEV_DB_DEFAULTS = {
            database: "mygems",
            username: "test",
            password: "test",
            host: "localhost",
            socket: "# this will need to be set manually"
        }.freeze

        ##
        # Default configuration settings for the test database.
        TEST_DB_DEFAULTS = {
            database: "testgems",
            username: "test",
            password: "test",
            host: "localhost",
        }.freeze

        ##
        # Beta setting used by Google App Engine to connect to the Cloud SQL
        # instance.
        BETA_SETTING_DEFAULTS = {
          "cloud_sql_instances" => "# automatically set"
        }.freeze

        ##
        # Setting used by Google App Engine to disable health checks for
        # faster deploys.
        HEALTH_CHECK_DEFAULT = {
          "enable_health_check" => false
        }.freeze

        ##
        # Setting used by Google App Engine to enable auto scaling.
        AUTO_SCALING_DEFAULT = {
          "min_num_instances" => 1,
          "max_num_instances" => 5
        }.freeze

        ##
        # Default configuration settings for the production gemserver.
        DEFAULT_CONFIG = {
          db_connection_options: PROD_DB_DEFAULTS,
          db_adapter: "cloud_sql",
          cache_type: "memory",
          protected_fetch: true,
          bind: "tcp://0.0.0.0:8080",
          :log_file => :stdout
        }.freeze

        ##
        # Default configuration settings for the development gemserver.
        DEFAULT_DEV_CONFIG = {
          db_connection_options: DEV_DB_DEFAULTS,
          db_adapter: "cloud_sql",
          cache_type: "memory",
          protected_fetch: true,
          bind: "tcp://0.0.0.0:8080",
          :log_file => :stdout
        }.freeze

        ##
        # Default configuration settings for the test gemserver.
        DEFAULT_TEST_CONFIG = {
          db_connection_options: TEST_DB_DEFAULTS,
          db_adapter: "sqlite3",
          cache_type: "memory",
          protected_fetch: true,
          bind: "tcp://0.0.0.0:8080",
          :log_file => :stdout
        }.freeze

        ##
        # Prefix for all general configuration setting fields in app.yaml.
        CONFIG_PREFIX = "gen".freeze

        ##
        # Prefix for all database configuration setting fields in app.yaml.
        CONFIG_DB_PREFIX = "db".freeze

        ##
        # Environment variables used by app.yaml for gemserver deployment.
        APP_ENGINE_ENV_VARS = {
          "GEMSERVER_ON_APPENGINE" => true,
          "production_db_database" => "mygems",
          "production_db_username" => "test",
          "production_db_password" => "test",
          "production_db_host" => "localhost",
          "production_db_socket" => "# this is set automatically",
          "production_db_adapter" => "cloud_sql",
          "dev_db_database" => "mygems",
          "dev_db_username" => "test",
          "dev_db_password" => "test",
          "dev_db_host" => "localhost",
          "dev_db_socket" => "# this must be set manually",
          "dev_db_adapter" => "cloud_sql",
          "test_db_database" => "mygems",
          "test_db_username" => "test",
          "test_db_password" => "test",
          "test_db_host" => "localhost",
          "test_db_adapter" => "sqlite3",
          "gen_cache_type" => "memory",
          "gen_protected_fetch" => true,
          "gen_bind" => "tcp://0.0.0.0:8080",
          "gen_log_file" => :stdout
        }.freeze

        ##
        # Default settings for gemserver deployment to Google App Engine via
        # app.yaml.
        APP_DEFAULTS = {
          "runtime" => "ruby",
          "env" => "flex",
          "entrypoint" => "./bin/google-cloud-gemserver start",
          "beta_settings" => BETA_SETTING_DEFAULTS,
          "health_check" =>  HEALTH_CHECK_DEFAULT,
          "automatic_scaling" => AUTO_SCALING_DEFAULT,
          "env_variables" => APP_ENGINE_ENV_VARS
        }.freeze

        ##
        # @private Temporary directory created to prepare a gemserver deploy
        # to a Google Cloud Platform project.
        SERVER_PATH = File.join("/tmp", "google-cloud-gemserver").freeze

        ##
        # @private Path to the configuration file on Google Cloud Storage that
        # was last used for a gemserver deploy. This path is checked by the
        # `config` command to display the last deployed gemserver's
        # configuration.
        GCS_PATH    = "#{SERVER_PATH}/config.yml".freeze

        ##
        # @private The path to the app folder on a deployed gemserver.
        GAE_DIR     = "/app".freeze

        ##
        # @private The path to the configuration file on a deployed gemserver.
        GAE_PATH    = File.join(GAE_DIR, "config.yml").freeze

        ##
        # @private The path to the credentials file used by the `gem` command.
        CREDS_PATH = File.expand_path(File.join("~", ".gem", "credentials"))
          .freeze

        ##
        # @private Base directory containing configuration files.
        CONFIG_DIR  = File.expand_path(File.join("~", ".google_cloud_gemserver"))

        ##
        # The name of the gem.
        GEM_NAME    = "google-cloud-gemserver".freeze

        ##
        # @private The default name of the gemserver key.
        DEFAULT_KEY_NAME = "master-gemserver-key".freeze

        ##
        # The configuration used by the gemserver.
        # @return [Hash]
        attr_accessor :config

        ##
        # The configuration used by gcloud to deploy the gemserver to Google
        # App Engine.
        # @return [Hash]
        attr_accessor :app

        ##
        # Instantiate a new instance of Configuration
        def initialize
          @app    = load_app
          @config = load_config
        end

        ##
        # Saves the configuration file used for a deployment.
        def save_to_cloud
          puts "Saving configuration"
          GCS.upload config_path, GCS_PATH
        end

        ##
        # Deletes the configuration file used for a deployment
        def delete_from_cloud
          GCS.delete_file GCS_PATH
        end

        ##
        # Updates the configuration file.
        #
        # @param [String] value New value of the key.
        # @param [String] key Name of the key that will be updated.
        # @param [String] sub_key Name of the sub key that will be updated.
        def update_config value, key, sub_key = nil
          if sub_key
            @config[key][sub_key] = value
          else
            @config[key] = value
          end
          write_config
        end
        # Updates the app configuration file.
        #
        # @param [String] value New value of the key.
        # @param [String] key Name of the key that will be updated.
        # @param [String] sub_key Name of the sub key that will be updated.
        def update_app value, key, sub_key = nil
          if sub_key
            @app[key][sub_key] = value
          else
            @app[key] = value
          end
          write_app
        end

        ##
        # Accesses a key in the Configuration object.
        #
        # @param [String] key Name of the key accessed.
        #
        # @return [String]
        def [] key
          @config[key]
        end

        ##
        # @private Generates a set of configuration files for the gemserver to
        # run and deploy to Google App Engine.
        def gen_config
          return if on_appengine
          FileUtils.mkpath config_dir unless Dir.exist? config_dir

          write_file "#{config_dir}/app.yaml",        app_config, true
          write_file "#{config_dir}/config.yml",      prod_config
          write_file "#{config_dir}/dev_config.yml",  dev_config
          write_file "#{config_dir}/test_config.yml", test_config
        end

        ##
        # Fetches the path to the relevant configuration file based on the
        # environment (production, test, development).
        #
        # @return [String]
        def config_path
          "#{config_dir}/#{suffix}"
        end

        ##
        # Fetches the path to the relevant app configuration file.
        #
        # @return [String]
        def app_path
          "#{config_dir}/app.yaml"
        end

        ##
        # Displays the configuration used by the current gemserver
        def self.display_config
          unless deployed?
            puts "No configuration found. Was the gemserver deployed?"
            return
          end
          prepare config
          puts "Gemserver is running with this configuration:"
          puts YAML.load_file(GCS_PATH).to_yaml
          cleanup
        end

        ##
        # Checks if the gemserver was deployed by the existence of the config
        # file used to deploy it on a specific path on Google Cloud Storage.
        #
        # @return [Boolean]
        def self.deployed?
          !GCS.get_file(GCS_PATH).nil?
        end

        private

        ##
        # @private Fetches the current environment.
        #
        # @return [String]
        def env
          ENV["APP_ENV"].nil? == true ? "production" : ENV["APP_ENV"]
        end

        ##
        # @private Determines which configuration file to read based on the
        # environment.
        #
        # @return [String]
        def suffix
          if env == "dev"
            "dev_config.yml"
          elsif env == "test"
            "test_config.yml"
          else
            "config.yml"
          end
        end

        ##
        # @private Writes a given file to a given path.
        #
        # @param [String] path The path to write the file.
        #
        # @param [String] content The content to be written to the file.
        #
        # @param [boolean] check_existence If true, the file is not overwritten
        # if it already exists. Optional.
        def write_file path, content, check_existence = false
          if check_existence
            return if File.exist? path
          end
          File.open(path, "w") do |f|
            f.write content
          end
        end

        ##
        # @private The default app.yaml configuration formatted in YAML.
        #
        # @return [String]
        def app_config
          APP_DEFAULTS.merge(load_app).to_yaml
        end

        ##
        # @private The default config.yml configuration formatted in YAML
        # used by the gemserver in the production environment.
        #
        # @return [String]
        def prod_config
          DEFAULT_CONFIG.deep_merge(extract_config("production")).to_yaml
        end

        ##
        # @private The default dev_config.yml configuration formatted in YAML
        # used by the gemserver in the dev environment.
        #
        # @return [String]
        def dev_config
          DEFAULT_DEV_CONFIG.deep_merge(extract_config("dev")).to_yaml
        end

        ##
        # @private The default test_config.yml configuration formatted in YAML
        # used by the gemserver in the test environment.
        #
        # @return [String]
        def test_config
          DEFAULT_TEST_CONFIG.deep_merge(extract_config("test")).to_yaml
        end

        ##
        # @private Extracts the gemserver configuration from the app.yaml
        # environment variables.
        #
        # @param [String] pre The prefix of the config fields to extract.
        #
        # @return [Hash]
        def extract_config pre = "production"
          adapter = pre + "_" + CONFIG_DB_PREFIX + "_adapter"
          db_config = @app["env_variables"].map do |k, v|
            # db_adapter is a special case b/c it has the 'db' in its name but is
            # not a db_connection_options field
            next unless k.include?(pre) && k != adapter
            [(k[pre.size + CONFIG_DB_PREFIX.size + 2..k.size - 1]).to_sym, v]
          end.compact.to_h
          config = @app["env_variables"].map do |k, v|
            next unless k.include? CONFIG_PREFIX
            [(k[CONFIG_PREFIX.size + 1..k.size - 1]).to_sym, v]
          end.compact.to_h
          {
            :db_connection_options => db_config,
            :db_adapter => @app["env_variables"][adapter]
          }.deep_merge config
        end

        ##
        # @private Loads a configuration file.
        #
        # @return [Hash]
        def load_config
          extract_config env
        end

        ##
        # @private Loads the app configuration file.
        #
        # @return [Hash]
        def load_app
          return APP_DEFAULTS unless File.exist? app_path
          YAML.load_file app_path
        end

        ##
        # @private Writes the current Configuration object in YAML format
        # to the relevant configuration file (based on environment) and
        # updates app.yaml accordingly.
        def write_config
          db_key = env + "_" + CONFIG_DB_PREFIX + "_"
          key = CONFIG_PREFIX + "_"
          db = @config[:db_connection_options]
          non_db = @config.reject { |k, v| k == :db_connection_options }
          formatted_db = db.map { |k, v| [db_key + k.to_s, v] }.to_h
          formatted_non_db = non_db.map { |k, v| [key + k.to_s, v] }.to_h
          @app["env_variables"] = @app["env_variables"].merge(
            formatted_db.merge(formatted_non_db)
          )
          File.open(config_path, "w") { |f| YAML.dump @config, f }
          write_app
        end

        ##
        # @private Writes the current app configuration object in YAML format
        # to the app configuration file.
        def write_app
          File.open(app_path, "w") { |f| YAML.dump @app, f }
        end

        ##
        # @private Fetches the directory that contains the configuration files.
        #
        # @return [String]
        def config_dir
          return GAE_DIR if on_appengine
          dir = ENV["GEMSERVER_CONFIG_DIR"]
          dir.nil? == true ? CONFIG_DIR : dir
        end

        ##
        # @private Determines if the gemserver is running on Google App Engine.
        #
        # @return [boolean]
        def on_appengine
          !ENV["GEMSERVER_ON_APPENGINE"].nil?
        end

        ##
        # @private Creates a temporary directory to download the configuration
        # file used to deploy the gemserver.
        def self.prepare file
          FileUtils.mkpath SERVER_PATH
          file.download file.name
        end

        ##
        # @private Deletes a temporary directory.
        def self.cleanup
          FileUtils.rm_rf SERVER_PATH
        end

        private_class_method :prepare
        private_class_method :cleanup
      end
    end
  end
end
