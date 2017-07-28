# Copyright 2017 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  @https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "google/cloud/gemserver"
require "net/http"
require "yaml"

module Google
  module Cloud
    module Gemserver
      class CLI
        ##
        #
        # # Request
        #
        # Responsible for sending requests to the gemserver for operations that
        # involve the database. Gem operations are done with the 'gem' command
        # and are not in the scope of Request.
        class Request

          ##
          # The HTTP object used to connect to and send requests to the
          # gemserver.
          # @return [Net::HTTP]
          attr_accessor :http

          ##
          # Initialize the Backend object by constructing an HTTP object for the
          # gemserver.
          def initialize url = nil
            gemserver_url = url.nil? == true ? remote : url
            @http = Net::HTTP.new gemserver_url, 8080
          end

          ##
          # Send a request to the gemserver to create a key with certain
          # permissions.
          #
          # @param [String] permissions The permissions the generated key will
          # have (read, write, or both). Optional.
          #
          # @return [String]
          def create_key permissions = nil
            send_req Net::HTTP::Post, "/api/v1/key", {permissions: permissions}
          end

          ##
          # Send a request to the gemserver to delete a key.
          #
          # @param [String] key The key to delete.
          #
          # @return [String]
          def delete_key key
            send_req Net::HTTP::Put, "/api/v1/key", {key: key}
          end

          ##
          # Send a request to the gemserver to fetch information about stored
          # private gems and cached gem dependencies.
          #
          # @return [String]
          def stats
            send_req Net::HTTP::Get, "/api/v1/stats"
          end

          private

          def remote
            descrip = YAML.load(`gcloud app describe`)
            descrip["defaultHostname"]
          end

          ##
          # @private Makes a request to the gemserver and returns the response.
          #
          # @param [Net::HTTP] type The type of HTTP request.
          #
          # @param [String] endpoint The endpoint the request is made to on the
          # gemserver.
          #
          # @param [Object] params The data passed to the gemserver to be
          # processed. Optional.
          #
          # @return [String]
          def send_req type, endpoint, params = nil
            req = type.new endpoint
            if type != Net::HTTP::Get
              req.set_form_data(params) if params
            end
            (@http.request req).body
          end
        end
      end
    end
  end
end
