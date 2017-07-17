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
require "fileutils"

describe Google::Cloud::Gemserver::Configuration do
  before(:all) do
    ENV["APP_ENV"] = "dev"
    @config = GCG::Configuration.new
    ConfigHelper.new.copy_configs
  end

  let(:dir) { GCG::Configuration::CONFIG_DIR }

  let(:app_path) {
    "#{dir}/app.yaml"
  }

  let(:config_path) {
    "#{dir}/config.yml"
  }

  let(:dev_config_path) {
    "#{dir}/dev_config.yml"
  }

  let(:the_test_config_path) {
    "#{dir}/test_config.yml"
  }

  after(:all) do
    ConfigHelper.new.restore_configs
  end

  describe "managing configurations" do
    it "must get the correct config paths" do
      @config.stub :config_dir, dir do
        ENV["APP_ENV"] = "test"
        assert_equal File.expand_path(the_test_config_path),
                     File.expand_path(@config.config_path)
        ENV["APP_ENV"] = "production"
        assert_equal File.expand_path(config_path),
                     File.expand_path( @config.config_path)
        ENV["APP_ENV"] = "dev"
        assert_equal File.expand_path(dev_config_path),
                     File.expand_path( @config.config_path)
        assert_equal File.expand_path(app_path),
                     File.expand_path(@config.app_path)
      end
    end

    it "must access keys in project config correctly" do
      @config.stub :config_dir, dir do
        assert_equal ConfigHelper.new.name, @config[:proj_id]
      end
    end

    it "must update project config correctly" do
      @config.stub :config_dir, dir do
        @config.update_config "ruby", :test
        assert_equal "ruby", @config[:test]
      end
    end

    it "must update app config correctly" do
      @config.stub :config_dir, dir do
        @config.update_app "ruby", :test
        app = YAML.load_file app_path
        assert_equal "ruby", app[:test]
      end
    end

    it "must save project config to GCS" do
      @config.stub :config_dir, dir do
        @config.save_to_cloud
        assert_equal true, GCG::GCS.on_gcs?(GCG::Configuration::GCS_PATH)
        GCG::GCS.delete_file GCG::Configuration::GCS_PATH
      end
    end

    it "must be able to display config" do
      @config.stub :config_dir, dir do
        @config.save_to_cloud
        out, err = capture_io { GCG::Configuration.display_config }
        did_output = out.include?("No configuration") ||
                     out.include?("Gemserver is running")
        assert_equal true, did_output
        GCG::GCS.delete_file GCG::Configuration::GCS_PATH
      end
    end
  end
end
