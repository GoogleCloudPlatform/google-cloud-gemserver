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

module Google
  module Cloud
    module Gemserver
      ##
      #
      # # Authentication
      #
      # Manages the permissions of the currently logged in user with the gcloud
      # sdk.
      #
      class Authentication

        ##
        # The project id of the Google App Engine project the gemserver was
        # deployed to.
        # @return [String]
        attr_accessor :proj

        ##
        # Creates the Authentication object and sets the project id field.
        def initialize
          @proj = Configuration.new[:proj_id]
        end

        ##
        # Checks if the currently logged in user can modify the gemserver
        # i.e. create keys.
        #
        # @return [Boolean]
        def can_modify?
          user = curr_user
          owners.each do |owner|
            return true if extract_account(owner) == user
          end
          editors.each do |editor|
            return true if extract_account(editor) == user
          end
          false
        end

        private

        ##
        # @private Fetches the members with a specific role that have access
        # to the Google App Engine project the gemserver was deployed to.
        #
        # @return [Array]
        def members type
          yml = YAML.load(run_cmd "gcloud projects get-iam-policy #{@proj}")
          yml["bindings"].select do |member_set|
            member_set["role"] == type
          end[0]["members"]
        end

        ##
        # @private Fetches members with a role of editor that can access the
        # gemserver.
        #
        # @return [Array]
        def editors
          members "roles/editor"
        end

        ##
        # @private Fetches members with a role of owner that can access the
        # gemserver.
        #
        # @return [Array]
        def owners
          members "roles/owner"
        end

        ##
        # @private Fetches the active account of the currently logged in user.
        #
        # @return [String]
        def curr_user
          raw = run_cmd "gcloud auth list"
          active_idx = raw.index("*")
          abort "You are not authenticated with gcloud" unless active_idx
          raw[active_idx + 1 .. raw.index("\n", active_idx)].strip
        end

        ##
        # @private Parses a gcloud "member" and removes the account prefix.
        #
        # @param [String] acc The member the account is extracted from.
        #
        # @return [String]
        def extract_account acc
          acc[acc.index(":") + 1 .. acc.size]
        end

        ##
        # @private Runs a given command on the local machine.
        #
        # @param [String] args The command to be run.
        def run_cmd args
          `#{args}`
        end
      end
    end
  end
end
