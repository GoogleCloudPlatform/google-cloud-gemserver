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
require "rubygems/dependency_installer"

module Google
  module Cloud
    module Gemserver
      ##
      #
      # # GemstashInstaller
      #
      # Responsible for checking a valid version of gemstash is installed and
      # upgrades its version if invalid. The gemstash installation is deemed
      # valid if it supports protected (authorized) gem fetches.
      module GemstashInstaller

        ##
        # The official name of the gemstash gem
        GEM_NAME = "gemstash".freeze

        ##
        # The URL to the official gemstash repository.
        GEM_URL = "https://github.com/bundler/gemstash.git".freeze

        ##
        # The name of the special permission in gemstash enabling
        # protected fetches.
        PERMISSION = "fetch".freeze

        ##
        # Checks the installed version of gemstash and upgrades it if necessary
        # . If it does not exist, the most recent version of gemstash is
        # installed.
        def self.check_and_install_gemstash
          if gemstash_detected
            upgrade_gemstash unless valid_gemstash
          else
            install_gemstash
          end
        end

        ##
        # @private Detects if gemstash is installed on the user's machine.
        #
        # @return [Boolean]
        def self.gemstash_detected
          dep = Gem::Dependency.new GEM_NAME
          !dep.matching_specs.max_by(&:version).nil?
        end

        ##
        # @private Determines if the gemstash version is valid by the presence
        # of the "fetch" permission which enables protected fetching.
        #
        # @return [Boolean]
        def self.valid_gemstash
          require "gemstash"
          Gemstash::Authorization::VALID_PERMISSIONS.include? PERMISSION
        end

        ##
        # @private Installs the newest version of gemstash by cloning the
        # public repository's master branch.
        def self.install_gemstash
          puts "Installing core missing dependency (gemstash)..."
          begin
            clone_repo
            build_and_install_gem
          ensure
            cleanup
          end
        end

        ##
        # @private Builds gemstash from the latest revision on the master
        # branch of its public repository then installs from the gemspec.
        def self.build_and_install_gem
          Dir.chdir GEM_NAME do
            spec = Gem::Specification.load "#{GEM_NAME}.gemspec"
            gem = Gem::Package.build spec
            Gem::DependencyInstaller.new.install gem
          end
        end

        ##
        # @private Uninstalls the current version of gemstash.
        def self.uninstall_gemstash
          puts "Uninstalling gemstash..."
          system "gem uninstall -x gemstash"
        end

        ##
        # @private Upgrades the current installed gemstash version to the
        # latest version on the public repository.
        def self.upgrade_gemstash
          puts "Upgrading gemstash by reinstalling it..."
          uninstall_gemstash
          install_gemstash
        end

        ##
        # @private Clones the public gemstash repository.
        def self.clone_repo
          system "git clone #{GEM_URL} > /dev/null 2>&1"
        end

        ##
        # @private Deletes the temporarily cloned gemstash repository.
        def self.cleanup
          system "rm -rf #{GEM_NAME}"
        end
      end
    end
  end
end
