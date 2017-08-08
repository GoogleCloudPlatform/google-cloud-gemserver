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
require "thor"

module Google
  module Cloud
    module Gemserver
      ##
      #
      # # CLI
      #
      # The command line interface which provides methods to interact with a
      # gemserver and deploy it to a given Google Cloud Platform project.
      #
      class CLI < Thor
        autoload :Project,         "google/cloud/gemserver/cli/project"
        autoload :CloudSQL,        "google/cloud/gemserver/cli/cloud_sql"
        autoload :Server,          "google/cloud/gemserver/cli/server"
        autoload :Request,         "google/cloud/gemserver/cli/request"

        # Error class thrown when a command that does not exist is run.
        class Error < Thor::Error
          def initialize cli, message
            super cli.set_color(message, :red)
          end
        end

        def self.start args = ARGV
          Configuration.new.gen_config
          super
        end

        ##
        # Starts the gemserver by starting up gemstash.
        desc "start", "Starts the gem server. This will be run automatically" \
          " after a deploy. Running this locally will start the gemserver "\
          "locally"
        def start
          Server.new.start
        end

        ##
        # Creates a gemserver app and deploys it to a Google Cloud Platform
        # project. An existing Google Cloud Platform project must be provided
        # through the --use-proj option and an existing Cloud SQL instance may
        # be provided through the --use-inst option, otherwise a new one will
        # be created.
        desc "create", "Creates and deploys the gem server then starts it"
        method_option :use_proj, type: :string, aliases: "-g", desc:
          "Existing project to deploy gemserver to"
        method_option :use_inst, type: :string, aliases: "-i", desc:
          "Existing project to deploy gemserver to"
        method_option :platform, type: :string, aliases: "-p", default: "gae",
          desc: "The platform to deploy the gemserver to (gae or gke)"
        def create
          prepare
          Server.new.deploy
        end

        ##
        # Retrieves a Google Cloud Platform instance and informs the user to
        # enable necessary APIs for that project. Also creates a Cloud SQL
        # instance if one was not provided with the --use-inst option.
        desc "prepare", "Uses a project on Google Cloud Platform and deploys"\
          " a gemserver to it."
        method_option :use_proj, type: :string, aliases: "-g", desc:
          "Existing project to deploy gemserver to"
        method_option :use_inst, type: :string, aliases: "-i", desc:
          "Existing Cloud SQL instance to us"
        method_option :platform, type: :string, aliases: "-p", default: "gae",
          desc: "The platform to deploy the gemserver to (gae or gke)"
        def prepare
          Project.new(options[:use_proj]).create options[:platform]
          CloudSQL.new(options[:use_inst]).run
        end

        ##
        # Updates the gemserver on Google Cloud Platform to the latest version
        # of the gemserver installed on the user's system.
        desc "update", "Redeploys the gemserver with the current config file" \
          " and google-cloud-gemserver gem version (a deploy must have " \
          "succeeded for 'update' to work."
        method_option :use_proj, type: :string, aliases: "-g", desc:
          "The project / service to update."
        method_option :platform, type: :string, aliases: "-p", default: "gae",
          desc: "The platform to update the gemserver on (gae or gke)"
        def update
          Project.new.send :update_metadata, options[:platform]
          Server.new.update options[:use_proj]
        end

        ##
        # Deletes a gemserver. This deletes the Google Cloud Platform project,
        # all associated Cloud SQL instances, and all Cloud Storage buckets.
        desc "delete", "Deletes a gemserver and its resources"
        method_option :platform, type: :string, aliases: "-p", default: "gae",
          desc: "The platform to delete the gemserver on (gae or gke)"
        def delete
          Project.new.send :update_metadata, options[:platform]
          Server.new.delete
        end

        ##
        # Creates a key used for installing or pushing gems to the given
        # gemserver with given permissions provided with the --permissions
        # option. By default, a key with all permissions is created.
        desc "create_key", "Creates an authentication key"
        method_option :permissions, type: :string, aliases: "-p", desc:
          "Options: write, read, both. Default is both."
        method_option :remote, type: :string, aliases: "-r", desc:
          "The gemserver URL, i.e. gemserver.com"
        method_option :use_proj, type: :string, aliases: "-g", desc:
          "The GCP project the gemserver was deployed to."
        def create_key
          if ENV["APP_ENV"] == "test"
            return Backend::Key.create_key(options[:permissions])
          end
          puts Request.new(options[:remote], options[:use_proj]).create_key(options[:permissions]).body
          Backend::Key.output_key_info
        end

        ##
        # Deletes a given key provided by the --key option from the given
        # gemserver.
        desc "delete_key", "Deletes a given key"
        method_option :key, type: :string, aliases: "-k", desc:
          "The key to delete"
        method_option :remote, type: :string, aliases: "-r", desc:
          "The gemserver URL, i.e. gemserver.com"
        method_option :use_proj, type: :string, aliases: "-g", desc:
          "The GCP project the gemserver was deployed to."
        def delete_key
          if ENV["APP_ENV"] == "test"
            return Backend::Key.delete_key(options[:key])
          end
          puts Request.new(options[:remote], options[:use_proj]).delete_key(options[:key]).body
        end

        ##
        # Displays the configuration used by the currently deployed gemserver.
        desc "config", "Displays the config the current deployed gemserver is"\
          " using (if one is running)"
        def config
          Configuration.display_config
        end

        ##
        # Displays statistics on the given gemserver such as private gems,
        # cached gems, gemserver creation time, etc.
        desc "stats", "Displays statistics on the given gemserver"
        method_option :remote, type: :string, aliases: "-r", desc:
          "The gemserver URL, i.e. gemserver.com"
        method_option :use_proj, type: :string, aliases: "-g", desc:
          "The GCP project the gemserver was deployed to."
        def stats
          return Backend::Stats.new.run if ENV["APP_ENV"] == "test"
          Backend::Stats.new.log_app_description
          puts Request.new(options[:remote], options[:use_proj]).stats.body
        end

        desc "gen_config", "Generates configuration files with default" \
          " values"
        def gen_config
          Configuration.new.gen_config
        end
      end
    end
  end
end
