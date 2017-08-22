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
require "securerandom"
require "google/apis/sqladmin_v1beta4"
require "googleauth"
require "yaml"

module Google
  module Cloud
    module Gemserver
      class CLI
        ##
        # # CloudSQL
        #
        # CloudSQL manages the creation of a Cloud SQL instance as well as
        # the necessary database and user creation.
        #
        class CloudSQL
          ##
          # Permits SQL admin operations with the Cloud SQL API.
          SCOPES = ["https://www.googleapis.com/auth/sqlservice.admin"]
                   .freeze

          ##
          # An alias for the SqladminV1beta4 module.
          SQL = Google::Apis::SqladminV1beta4

          ##
          # The name of the database used to store gemserver data.
          # @return [String]
          attr_reader :db

          ##
          # The name of the default user created to access the database.
          # @return [String]
          attr_reader :user

          ##
          # The password of the default user created to access the database.
          # @return [String]
          attr_reader :pwd

          ##
          # The project ID of the project the gemserver will be deployed to.
          # @return [String]
          attr_reader :proj_id

          ##
          # The name of the Cloud SQL instance.
          # @return [String]
          attr_reader :inst

          ##
          # The Cloud SQL API used to manage Cloud SQL instances.
          # @return [Google::Apis::SqladminV1beta4::SQLAdminService]
          attr_reader :service

          ##
          # Creates a CloudSQL object and loads the necessary configuration
          # settings.
          #
          # @param inst [String] Name of the instance to be used. Optional.
          def initialize inst = nil
            auth = Google::Auth.get_application_default SCOPES
            Google::Apis::RequestOptions.default.authorization = auth
            @config = Configuration.new
            @service     = SQL::SQLAdminService.new
            @inst        = inst || "instance-#{SecureRandom.uuid}".freeze
            @custom      = inst ? true : false
            load_config
          end

          ##
          # Prepares a Cloud SQL instance with a database and user. Also saves
          # the database settings in the appropriate configuration file.
          def run
            create_instance do |instance_op|
              run_sql_task instance_op if instance_op.class == SQL::Operation
              update_root_user
              create_db do |db_op|
                run_sql_task db_op
                create_user
              end
            end
            update_config if @config.metadata[:platform] == "gae"
          end

          private

          ##
          # @private Creates a Cloud SQL instance.
          def create_instance &block
            if @custom
              puts "Using existing Cloud SQL instance: #{@inst}"
              yield
              return instance
            end
            puts "Creating Cloud SQL instance #{@inst} (this takes a few "\
              "minutes to complete)"
            settings = SQL::Settings.new(tier: "db-f1-micro")
            payload = SQL::DatabaseInstance.new(
              name: @inst,
              project: @proj_id,
              settings: settings
            )
            @service.insert_instance(@proj_id, payload, &block)
          end

          ##
          # @private Creates a database for a Cloud SQL instance.
          def create_db &block
            puts "Creating database #{@db}"
            db = SQL::Database.new name: @db
            @service.insert_database(@proj_id, @inst, db, &block)
          end

          ##
          # @private Creates a user for a Cloud SQL instance.
          def create_user
            puts "Creating user #{@user}"
            user = SQL::User.new(name: @user, password: @pwd)
            run_sql_task @service.insert_user(@proj_id, @inst, user)
          end

          ##
          # @private Updates the password of the root user if a new Cloud SQL
          # instance was created.
          def update_root_user
            return if @custom
            cmd = "gcloud sql users set-password root % --password #{@pwd} "\
              "-i #{@inst} --project #{@proj_id}"
            `#{cmd}`
          end

          ##
          # @private Fetches a Cloud SQL instance.
          #
          # @return [Google::Apis::SqladminV1beta4::DatabaseInstance
          def instance
            @service.get_instance @proj_id, @inst
          end

          ##
          # Deletes the Cloud SQL instance for a gemserver.
          def del_instance
            puts "Deleting instance: #{@inst}"
            @service.delete_instance @proj_id, @inst
          end

          ##
          # Sets various Cloud SQL settings used to create a Cloud SQL
          # instance.
          def load_config
            @db      = @config[:db_connection_options][:database]
            @user    = @config[:db_connection_options][:username]
            @pwd     = @config[:db_connection_options][:password]
            @proj_id = @config[:proj_id]
          end

          ##
          # Saves the Cloud SQL configuration in the appropriate configuration
          # file and app configuration file.
          def update_config
            puts "Updating configurations: app.yaml and config.yml "
            conn_name = instance.connection_name
            @config.update_config "/cloudsql/#{conn_name}",
                                  :db_connection_options,
                                  :socket
            @config.update_app conn_name, "beta_settings", "cloud_sql_instances"
          end

          ##
          # Runs a Cloud SQL task and polls for its completion.
          def run_sql_task op
            while @service.get_operation(@proj_id, op.name).status != "DONE"
              sleep 2
            end
          end
        end
      end
    end
  end
end
