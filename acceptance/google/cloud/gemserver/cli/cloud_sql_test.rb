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
require "google/apis/sqladmin_v1beta4"
require "googleauth"
require "yaml"

SQL = Google::Cloud::Gemserver::CLI::CloudSQL
CFG = Google::Cloud::Gemserver::Configuration
CSQL = Google::Apis::SqladminV1beta4
SCOPES = ["https://www.googleapis.com/auth/sqlservice.admin"]

describe Google::Cloud::Gemserver::CLI::CloudSQL do

  let(:auth) {
    auth= Google::Auth.get_application_default(SCOPES)
    Google::Apis::RequestOptions.default.authorization = auth
  }

  let(:service) {
    auth
    CSQL::SQLAdminService.new
  }

  before(:all) do
    @config = CFG.new
    @app_path = @config.app_path
    @config_path = @config.config_path
    ConfigHelper.new.copy_configs
  end

  after(:all) do
    ConfigHelper.new.restore_configs
  end

  describe "creating an instance" do
    it "must load the configuration" do
      sql = SQL.new("testdb")
      sql.send(:load_config)
      assert_equal CFG::DEV_DB_DEFAULTS[:username], sql.user
      assert_equal CFG::DEV_DB_DEFAULTS[:password], sql.pwd
      assert_equal CFG::DEV_DB_DEFAULTS[:database], sql.db
      assert_equal @config[:proj_id], sql.proj_id
    end

    it "must get the instance if it exists" do
      sql = SQL.new("testdb")
      inst = service.get_instance @config[:proj_id], "testdb"
      assert_equal inst.connection_name, sql.send(:instance).connection_name
    end

    it "must create an instance if it does not exist" do
      sql = SQL.new
      sql.run
      assert_equal CSQL::DatabaseInstance, sql.send(:instance).class
      sql.send(:del_instance)
    end

    it "must update the configuration file" do
      sql = SQL.new("testdb")
      sql.run
      config = YAML.load_file @config_path
      refute config[:db_connection_options][:socket].empty?
    end
  end

  describe "deleting an instance" do
    it "must delete the instance" do
      sql = SQL.new
      sql.run
      sql.send(:del_instance)
    end
  end
end
