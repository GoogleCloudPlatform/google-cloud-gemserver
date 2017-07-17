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

SQL = Google::Apis::SqladminV1beta4

describe Google::Cloud::Gemserver::CLI::CloudSQL do
  describe "CloudSQL.new" do
    it "must set the properties" do
      sql = GCG::CLI::CloudSQL.new
      config = GCG::Configuration.new
      assert sql.inst.include? "instance"
      assert sql.proj_id == config[:proj_id]
      assert sql.db == config[:db_connection_options][:database]
      assert sql.user == config[:db_connection_options][:username]
      assert sql.pwd == config[:db_connection_options][:password]
    end

    it "calls SQLAdminService.new.insert_instance" do
      sql = GCG::CLI::CloudSQL.new
      mock_create_inst = Minitest::Mock.new
      mock_create_inst.expect :call, nil, [sql.proj_id, SQL::DatabaseInstance]
      mock_task  = Minitest::Mock.new
      mock_task.expect :call, nil, [nil]

      sql.service.stub :insert_instance, mock_create_inst do
        sql.stub :update_root_user, nil do
          sql.stub :run_sql_task, mock_task do
            sql.send :create_instance
            mock_create_inst.verify
          end
        end
      end
    end

    it "calls SQLAdminService.new.insert_database" do
      sql = GCG::CLI::CloudSQL.new
      mock_create_db = Minitest::Mock.new
      mock_create_db.expect :call, nil, [sql.proj_id, String, SQL::Database]
      mock_task  = Minitest::Mock.new
      mock_task.expect :call, nil, [nil]

      sql.service.stub :insert_database, mock_create_db do
        sql.stub :update_root_user, nil do
          sql.stub :run_sql_task, mock_task do
            sql.send :create_db
            mock_create_db.verify
          end
        end
      end
    end

    it "calls SQLAdminService.new.insert_user" do
      sql = GCG::CLI::CloudSQL.new
      mock_create_user = Minitest::Mock.new
      mock_create_user.expect :call, nil, [sql.proj_id, String, SQL::User]
      mock_task  = Minitest::Mock.new
      mock_task.expect :call, nil, [nil]

      sql.service.stub :insert_user, mock_create_user do
        sql.stub :update_root_user, nil do
          sql.stub :run_sql_task, mock_task do
            sql.send :create_user
            mock_create_user.verify
          end
        end
      end
    end
  end

  describe ".del_instance" do
    it "calls SQLAdminService.new.delete_instance" do
      sql = GCG::CLI::CloudSQL.new
      mock_del_inst = Minitest::Mock.new
      mock_del_inst.expect :call, nil, [sql.proj_id, String]
      mock_task  = Minitest::Mock.new
      mock_task.expect :call, nil, [nil]

      sql.service.stub :delete_instance, mock_del_inst do
        sql.stub :update_root_user, nil do
          sql.stub :run_sql_task, mock_task do
            sql.send :del_instance
            mock_del_inst.verify
          end
        end
      end
    end
  end
end
