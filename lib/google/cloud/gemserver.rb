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

module Google
  module Cloud
    ##
    #
    # # Gemserver
    #
    # Gemserver provides a command line interface to create, manage, and deploy
    # a gemserver to a Google Cloud Platform project.
    #
    module Gemserver
      autoload :CLI,            "google/cloud/gemserver/cli"
      autoload :VERSION,        "google/cloud/gemserver/version"
      autoload :Configuration,  "google/cloud/gemserver/configuration"
      autoload :StorageSync,    "google/cloud/gemserver/storage_sync"
      autoload :GCS,            "google/cloud/gemserver/gcs"
      autoload :Authentication, "google/cloud/gemserver/authentication"

      ##
      #
      # # Backend
      #
      # Contains services that run on Google App Engine directly leveraging
      # tools such as Cloud SQL proxy.
      #
      module Backend
        autoload :GemstashServer, "google/cloud/gemserver/backend/gemstash_server"
        autoload :Key,            "google/cloud/gemserver/backend/key"
        autoload :Stats,          "google/cloud/gemserver/backend/stats"
      end
    end
  end
end
