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

require "patched/configuration"
require "patched/dependencies"
require "patched/env"
require "patched/gem_pusher"
require "patched/gem_yanker"
require "patched/storage"
require "patched/web"
require "gemstash"

module Google
  module Cloud
    module Gemserver
      module Backend
        ##
        #
        # # GemstashServer
        #
        # The class that runs gemstash specific commands and starts the gemstash
        # server. Parts of gemstash are monkey-patched with lib/patched for
        # compatibility with Google Cloud Platform services such as Cloud Storage
        # and Cloud SQL.
        module GemstashServer

          ##
          # Runs a given command through the gemstash gem.
          #
          # @param [String] args The argument passed to gemstash.
          def self.start args
            Gemstash::CLI.start args
          end

          ##
          # Fetches the gemstash environment given a configuration file.
          #
          # @param [String] config_path The path to the configuration file.
          #
          # @return [Gemstash::Env]
          def self.env config_path
            config = Gemstash::Configuration.new file: config_path
            Gemstash::Env.new config
          end
        end
      end
    end
  end
end
