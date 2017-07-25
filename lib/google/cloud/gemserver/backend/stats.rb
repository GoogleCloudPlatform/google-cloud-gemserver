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
require "yaml"

module Google
  module Cloud
    module Gemserver
      module Backend
        ##
        # # Stats
        #
        # Stats provides a set of methods that display detailed information
        # about the deployed gemserver. It includes: general Google Cloud
        # Platform project information, how long the gemserver has been running
        # , what private gems are stored, and what gems have been cached.
        #
        class Stats

          ##
          # The project ID of the project on Google Cloud Platform the
          # gemserver was deployed to.
          # @return [String]
          attr_accessor :proj

          ##
          # Initialize a Configuration object and project ID for the Stats
          # object enabling it to fetch detailed information about the
          # gemserver.
          def initialize
            @config = Google::Cloud::Gemserver::Configuration.new
            @proj = (@config[:proj_id] || nil).freeze
          end

          ##
          # Displays various sets of information about the gemserver such as
          # how long it has been running, currently stored, private gems and
          # their status, and cached gems.
          def run
            resp = ""
            resp << log_uptime
            resp << log_private_gems
            resp << log_cached_gems
          end

          ##
          # Displays information about the project on Google Cloud
          # Platform the gemserver was deployed to.
          def log_app_description
            return "" if ENV["APP_ENV"] == "test"
            set_project
            puts "Project Information:"
            puts run_cmd("gcloud app describe").gsub("\n", "\n\t").prepend "\t"
          end

          private

          ##
          # @private Displays the time of which the gemserver was deployed.
          def log_uptime
            return "" unless project
            "The gemserver has been running since #{project.created_at}\n"
          end

          ##
          # @private Displays the private gems stored on the gemserver and
          # their status (currently indexed or not).
          def log_private_gems
            res = "Private Gems:\n"
            versions = db :versions
            format = "%35s\t%20s\n"
            res << sprintf(format, "Gem Name - Version", "Available?")
            versions.map do |gem|
              res << sprintf(format, gem[:storage_id], gem[:indexed])
            end
            puts res
            res
          end

          ##
          # @private Displays the gems cached on the gemserver.
          def log_cached_gems
            res = "Cached Gem Dependencies:\n"
            cached = db :cached_rubygems
            format = "%35s\t%20s\n"
            res << sprintf(format, "Gem Name - Version", "Date Cached")
            cached.map do |gem|
              res << sprintf(format, gem[:name], gem[:created_at])
            end
            puts res
            res
          end

          ##
          # @private Fetches the Google Cloud Platform project the gemserver
          # was deployed to.
          #
          # @return [Project]
          def project
            if @proj.nil?
              return nil if ENV["APP_ENV"] == "test"
              raise ":proj_id not set in config file"
            end
            Google::Cloud::Gemserver::CLI::Project.new(@proj).send(:project)
          end

          ##
          # @private Fetches the Environment object currently being used by the
          # gemserver. It enables access to the database.
          #
          # @return [Gemstash::Env]
          def env
            GemstashServer.env @config.config_path
          end

          ##
          # @private Retrieves all the rows in the database for a given table.
          #
          # @param [String] table The table to be read.
          #
          # @return [Array]
          def db table
            env.db[table].all
          end

          ##
          # @private Sets the gcloud project to the project of the gemserver.
          def set_project
            run_cmd "gcloud config set project #{@proj}"
          end

          ##
          # @private Runs a given command on the local machine.
          #
          # @param [String] cmd The command to be run.
          def run_cmd cmd
            `#{cmd}`
          end
        end
      end
    end
  end
end
