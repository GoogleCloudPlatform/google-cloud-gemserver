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
require "google/cloud/storage"

GCS       = GCG::GCS

describe Google::Cloud::Gemserver::GCS do

  let(:proj_name) {
    ConfigHelper.new.name
  }

  before do
    @config = Google::Cloud::Gemserver::Configuration.new
    @config.update_config proj_name, :proj_id
  end

  describe "setting up Google Cloud Storage" do
    it "must get a GCS service instance for the current project" do
      assert_equal Google::Cloud::Storage::Project, GCS.cs.class
      assert_equal proj_name, GCS.cs.project
    end

    it "must get a GCS bucket" do
      assert_equal proj_name, GCS.bucket.name
    end
  end

  describe "managing files" do
    it "can get a file" do
      GCS.upload @config.config_path
      assert_equal Google::Cloud::Storage::File, GCS.get_file(@config.config_path).class
      GCS.delete_file @config.config_path
    end

    it "can get all files" do
      files = GCS.files
      assert_equal Google::Cloud::Storage::File::List, files.class
    end

    it "can upload a file" do
      assert_equal @config.config_path, GCS.upload(@config.config_path).name
      GCS.delete_file @config.config_path
    end

    it "can delete a file" do
      GCS.upload @config.config_path
      assert_equal true, GCS.delete_file(@config.config_path)
    end

    it "can sync a file between host and GCS" do
      GCS.upload @config.config_path
      assert_equal true, GCS.sync(@config.config_path)
      GCS.delete_file @config.config_path
    end

    it "can check if a file exists on GCS" do
      GCS.upload @config.config_path
      assert_equal true, GCS.on_gcs?(@config.config_path)
      GCS.delete_file @config.config_path
    end

    it "can get extract the dir name from a file path" do
      assert_equal "/a/b/c/", GCS.extract_dir("/a/b/c/file.file")
    end
  end
end
