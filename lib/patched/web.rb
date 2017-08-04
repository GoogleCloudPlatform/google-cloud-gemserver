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

require "gemstash"
require "google/cloud/gemserver"

##
# Monkeypatch gemstash to handle gemserver specific endpoints.
Gemstash::Web.class_eval do
  ##
  # Displays statistics on the currently deployed gemserver such as private
  # gems, cached gems, gemserver creation time, etc.
  post "/api/v1/stats" do
    auth = Google::Cloud::Gemserver::Authentication.new
    if auth.validate_token request.env["HTTP_GEMSERVER_CREDENTIALS"]
      content_type "application/json;charset=UTF-8"
      Google::Cloud::Gemserver::Backend::Stats.new.run
    else
      halt 401, "Unauthorized operation."
    end
  end

  ##
  # Creates a key used for installing or pushing gems to the gemserver
  # with given permissions. By default, a key with all permissions is created.
  post "/api/v1/key" do
    auth = Google::Cloud::Gemserver::Authentication.new
    if auth.validate_token request.env["HTTP_GEMSERVER_CREDENTIALS"]
      key = Google::Cloud::Gemserver::Backend::Key.create_key params["permissions"]
      content_type "application/json;charset=UTF-8"
      "Generated key: #{key}"
    else
      halt 401, "Unauthorized operation."
    end
  end

  ##
  # Deletes a key.
  put "/api/v1/key" do
    auth = Google::Cloud::Gemserver::Authentication.new
    if auth.validate_token request.env["HTTP_GEMSERVER_CREDENTIALS"]
      res = Google::Cloud::Gemserver::Backend::Key.delete_key params["key"]
      content_type "application/json;charset=UTF-8"
      if res
        "Deleted key #{params["key"]} successfully."
      else
        "Deleting key #{params["key"]} failed."
      end
    else
      halt 401, "Unauthorized operation."
    end
  end
end
