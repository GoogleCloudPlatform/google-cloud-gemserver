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
require "gemstash"

describe Google::Cloud::Gemserver::CLI::Server do
  describe "Server.new" do
    it "must set the properties" do
      server = GCG::CLI::Server.new
      assert server.config.class == GCG::Configuration.new.class
    end

  end

  describe ".start" do
    it "calls Gemstash::CLI.start" do
      server = GCG::CLI::Server.new
      mock_server = Minitest::Mock.new
      mock_server.expect :call, nil, [Array]

      Gemstash::CLI.stub :start, mock_server do
        Google::Cloud::Gemserver::Backend::StorageSync.stub :download_service, nil do
          server.start
          mock_server.verify
        end
      end
    end
  end

  describe ".deploy" do
    it "calls prepare_dir" do
      ENV["APP_ENV"] = "production"
      server = GCG::CLI::Server.new
      mock = Minitest::Mock.new
      mock.expect :call, nil

      server.stub :system, true do
        server.config.stub :save_to_cloud, nil do
          server.stub :setup_default_keys, nil do
            server.stub :display_next_steps, nil do
              server.stub :prepare_dir, mock do
                server.deploy
                mock.verify
              end
            end
          end
        end
      end

      ENV["APP_ENV"] = "test"
    end

    it "calls gcloud app deploy" do
      server = GCG::CLI::Server.new
      app_path = "#{GCG::Configuration::SERVER_PATH}/app.yaml"
      ENV["APP_ENV"] = "production"
      mock_server = Minitest::Mock.new
      mock_server.expect :call, true, ["gcloud app deploy #{app_path} -q --project #{server.config[:proj_id]}"]

      server.stub :system, mock_server do
        server.stub :prepare_dir, nil do
          server.config.stub :save_to_cloud, nil do
            server.stub :setup_default_keys, nil do
              server.stub :display_next_steps, nil do
                server.deploy
                mock_server.verify
              end
            end
          end
        end
      end
      ENV["APP_ENV"] = "test"
    end

    it "waits for the gemserver to be accessible" do
      ENV["APP_ENV"] = "production"
      server = GCG::CLI::Server.new
      mock = Minitest::Mock.new
      mock.expect :call, nil

      server.stub :prepare_dir, nil do
        server.config.stub :save_to_cloud, nil do
          server.stub :system, true do
            server.stub :setup_default_keys, nil do
              server.stub :display_next_steps, nil do
                server.stub :wait_until_server_accessible, mock do
                  server.deploy
                  mock.verify
                end
              end
            end
          end
        end
      end

      ENV["APP_ENV"] = "test"
    end

    it "saves the deploy config file to GCS" do
      ENV["APP_ENV"] = "production"
      server = GCG::CLI::Server.new
      mock = Minitest::Mock.new
      mock.expect :call, nil

      server.stub :prepare_dir, nil do
        server.stub :system, true do
          server.stub :setup_default_keys, nil do
            server.stub :display_next_steps, nil do
              server.stub :wait_until_server_accessible, nil do
                server.config.stub :save_to_cloud, mock do
                  server.deploy
                  mock.verify
                end
              end
            end
          end
        end
      end

      ENV["APP_ENV"] = "test"
    end

    it "calls setup_default_keys" do
      ENV["APP_ENV"] = "production"
      server = GCG::CLI::Server.new
      mock = Minitest::Mock.new
      mock.expect :call, nil

      server.stub :prepare_dir, nil do
        server.stub :system, true do
          server.config.stub :save_to_cloud, nil do
            server.stub :display_next_steps, nil do
              server.stub :wait_until_server_accessible, nil do
                server.stub :setup_default_keys, mock do
                  server.deploy
                  mock.verify
                end
              end
            end
          end
        end
      end
    end

    it "calls display_next_steps" do
      ENV["APP_ENV"] = "production"
      server = GCG::CLI::Server.new
      mock = Minitest::Mock.new
      mock.expect :call, nil

      server.stub :prepare_dir, nil do
        server.stub :system, true do
          server.config.stub :save_to_cloud, nil do
            server.stub :setup_default_keys, nil do
              server.stub :wait_until_server_accessible, nil do
                server.stub :display_next_steps, mock do
                  server.deploy
                  mock.verify
                end
              end
            end
          end
        end
      end
    end
  end

  describe ".update" do
    it "calls deploy" do
      server = GCG::CLI::Server.new
      mock_server = Minitest::Mock.new
      mock_server.expect :call, nil

      GCG::Configuration.stub :deployed?, true do
        server.stub :deploy, mock_server do
          server.update
          mock_server.verify
        end
      end
    end
  end

  describe ".delete" do
    it "calls gcloud projects delete" do
      server = GCG::CLI::Server.new

      config_mock = Minitest::Mock.new
      config_mock.expect :delete_from_cloud, nil
      mock_server = Minitest::Mock.new
      mock_server.expect :call, nil, ["gcloud projects delete bob"]

      GCG::Configuration.stub :new, config_mock do
        server.config.stub :delete_from_cloud, nil do
          server.stub :run_cmd, mock_server do
            server.delete "bob"
            mock_server.verify
          end
        end
      end
    end
  end
end
