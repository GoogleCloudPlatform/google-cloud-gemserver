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

require "helper"

describe Google::Cloud::Gemserver::GemstashInstaller do
  describe ".check_and_install_gemstash" do
    it "calls gemstash_detected" do
      #TODO
    end

    it "calls upgrade_gemstash or install_gemstash" do
      #TODO
    end

    it "calls valid_gemstash if gemstash is installed" do
      #TODO
    end
  end

  describe ".gemstash_detected" do
    it "correctly checks if gemstash is installed" do
      #TODO
    end
  end

  describe ".install_gemstash" do
    it "calls clone_repo" do
      #TODO
    end

    it "calls Gem::Package.build" do
      #TODO
    end

    it "calls Gem::DependencyInstaller" do
      #TODO
    end

    it "calls cleanup" do
      #TODO
    end
  end

  describe ".upgrade_gemstash" do
    it "calls uninstall_gemstash" do
      #TODO
    end

    it "calls install_gemstash" do
      #TODO
    end
  end
end
