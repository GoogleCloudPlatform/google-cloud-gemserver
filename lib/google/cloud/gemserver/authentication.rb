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
require "json"
require "securerandom"
require "googleauth"
require "net/http"
require "uri"

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
          puts "You are either not authenticated with gcloud or lack access" \
            " to the gemserver."
          false
        end

        ##
        # Generates an access token from a user authenticated by gcloud.
        #
        # @return [String]
        def access_token
          return unless can_modify?
          scope = ["https://www.googleapis.com/auth/cloud-platform"]
          auth = Google::Auth.get_application_default scope
          auth.fetch_access_token!
        end

        ##
        # Uses the tokeninfo API to validate the given access token.
        #
        # @param [String] auth_header The authorization header containing the
        # token, e.g. "Bearer [TOKEN]".
        #
        # @return [Boolean]
        def validate_token auth_header
          token = auth_header.split.drop(1)[0]
          apis_url = "https://www.googleapis.com"
          tokeninfo_endpoint = "/oauth2/v1/tokeninfo?access_token=#{token}"
          res = send_req apis_url, tokeninfo_endpoint, Net::HTTP::Post, token

          return false unless check_status(res)

          token_can_edit? token
        end

        private

        ##
        # @private Implicitly checks if the account that generated the token
        # has edit permissions on the Google Cloud Platform project by issuing
        # a redundant update to the project (update to original settings).
        #
        # @param [String] The authentication token generated from gcloud.
        #
        # @return [Boolean]
        def token_can_edit? token
          appengine_url = "https://appengine.googleapis.com"
          endpoint = "/v1/apps/#{@proj}/services/default?updateMask=split"
          version = appengine_version token
          split = {
            "split" => {
              "allocations" => {
                version.to_s => 1
              }
            }
          }
          res = send_req appengine_url, endpoint, Net::HTTP::Patch, token, split
          check_status res
        end

        ##
        # @private Fetches the latest version of the deployed Google App Engine
        # instance running the gemserver (default service only).
        #
        # @param [String] The authentication token generated from gcloud.
        #
        # @return [String]
        def appengine_version token
          appengine_url = "https://appengine.googleapis.com"
          path = "/v1/apps/#{@proj}/services/default"
          res = send_req appengine_url, path, Net::HTTP::Get, token

          fail "Unauthorized" unless check_status(res)

          eval(res.body)[:split][:allocations].first[0]
        end

        ##
        # @private Sends a request to a given URL with given parameters.
        #
        # @param [String] dom The protocol + domain name of the request.
        #
        # @param [String] path The path of the URL.
        #
        # @param [Net::HTTP] type The type of request to be made.
        #
        # @param [String] token The authentication token used in the header.
        #
        # @param [Hash] params Additional parameters send in the request body.
        #
        # @return [Net::HTTPResponse]
        def send_req dom, path, type, token, params = nil
          uri = URI.parse dom
          http = Net::HTTP.new uri.host, uri.port
          if dom.include? "https"
            http.use_ssl = true
          end
          req = type.new path
          req["Authorization"] = Signet::OAuth2.generate_bearer_authorization_header token
          unless type == Net::HTTP::Get
            if params
              req["Content-Type"] = "application/json"
              req.body = params.to_json
            end
          end
          http.request req
        end

        ##
        # @private Checks if a request response matches a given status code.
        #
        # @param [Net::HTTPResponse] reponse The response from a request.
        #
        # @param [Integer] code The desired response code.
        #
        # @return [Boolean]
        def check_status response, code = 200
          response.code.to_i == code
        end

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
          raw = run_cmd "gcloud auth list --format json"
          JSON.load(raw).map do |i|
            return i["account"] if i["status"] == "ACTIVE"
          end
          abort "You are not authenticated with gcloud"
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
