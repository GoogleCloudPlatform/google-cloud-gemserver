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

gem "minitest"

require "minitest/autorun"
require "minitest/rg"
require "google/cloud/gemserver"

GCG = Google::Cloud::Gemserver

class ConfigHelper
  def initialize
    ENV["APP_ENV"] = "dev"
    @config = Google::Cloud::Gemserver::Configuration.new
  end

  def copy_configs
    @config.update_config name, :proj_id
    FileUtils.cp @config.app_path, "/tmp/gemserver-app-config.yaml"
    FileUtils.cp @config.config_path, "/tmp/gemserver-config.yml"
  end

  def restore_configs
    FileUtils.rm @config.app_path
    FileUtils.rm @config.config_path
    FileUtils.cp "/tmp/gemserver-app-config.yaml", @config.app_path
    FileUtils.cp "/tmp/gemserver-config.yml", @config.config_path
  end

  def name
    @config[:proj_id]
  end
end
