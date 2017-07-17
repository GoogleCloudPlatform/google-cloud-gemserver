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
require "yaml"

Project = Google::Cloud::Gemserver::CLI::Project

describe Google::Cloud::Gemserver::CLI::Project do

  before do
    @config = Google::Cloud::Gemserver::Configuration.new
    @config_path = @config.config_path
  end

  let(:reset_config) {
    config = YAML.load_file @config_path
    config[:proj_id] = ""
    File.open(@config_path, 'w') {|f| YAML.dump config, f}
  }

  after do
    config = YAML.load_file @config_path
    config[:proj_id] = ConfigHelper.new.name
    File.open(@config_path, 'w') {|f| YAML.dump config, f}
  end

  describe "managing a project" do

    before do
      Google::Cloud::Gemserver::CLI::Project.class_eval do
        private
        def prompt_user; end
      end
    end

    it "must be possible to use an existing project" do
      project = Project.new(@config[:proj_id]).create
      assert_equal Google::Cloud::ResourceManager::Project, project.class
    end

    it "must update the config file correctly" do
      reset_config
      project = Project.new(@config[:proj_id]).create
      config = YAML.load_file @config_path
      assert_equal project.project_id, config[:proj_id]
    end
  end
end
