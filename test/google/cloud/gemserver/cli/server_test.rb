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

  let(:gae) { { platform: "gae" } }
  let(:gke) { { platform: "gke" } }

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
    it "calls the Deployer" do
      server = GCG::CLI::Server.new
      mock = Minitest::Mock.new
      mock.expect :deploy, nil
      ENV["APP_ENV"] = "production"
      server.stub :setup_default_keys, nil do
        server.stub :prepare_dir, nil do
          server.stub :wait_until_server_accessible, nil do
            server.config.stub :save_to_cloud, nil do
              server.stub :display_next_steps, nil do
                server.stub :cleanup, nil do
                  GCG::Deployer.stub :new, mock do
                    server.deploy
                    mock.verify
                  end
                end
              end
            end
          end
        end
      end
      ENV["APP_ENV"] = "test"
    end

    it "sets up default keys" do
      server = GCG::CLI::Server.new
      mock = Minitest::Mock.new
      mock.expect :call, nil
      ENV["APP_ENV"] = "production"
      server.stub :setup_default_keys, mock do
        server.stub :base_deploy, nil do
          server.stub :cleanup, nil do
            server.deploy
            mock.verify
          end
        end
      end
      ENV["APP_ENV"] = "test"
    end
  end

  describe ".base_deploy" do
    it "calls prepare_dir" do
      server = GCG::CLI::Server.new

      mock = Minitest::Mock.new
      mock.expect :call, nil
      deployer_mock = Minitest::Mock.new
      deployer_mock.expect :deploy, nil

      GCG::Deployer.stub :new, deployer_mock do
        server.config.stub :save_to_cloud, nil do
          server.stub :display_next_steps, nil do
            server.stub :prepare_dir, mock do
              server.stub :wait_until_server_accessible, nil do
                server.send :base_deploy
                mock.verify
              end
            end
          end
        end
      end
    end

    it "calls Deployer.new.deploy" do
      server = GCG::CLI::Server.new

      mock = Minitest::Mock.new
      mock.expect :deploy, nil

      server.stub :prepare_dir, nil do
        server.stub :wait_until_server_accessible, nil do
          server.config.stub :save_to_cloud, nil do
            server.stub :display_next_steps, nil do
              GCG::Deployer.stub :new, mock do
                server.send :base_deploy
                mock.verify
              end
            end
          end
        end
      end
    end

    it "waits for the gemserver to be accessible" do
      server = GCG::CLI::Server.new

      mock = Minitest::Mock.new
      mock.expect :call, nil
      deployer_mock = Minitest::Mock.new
      deployer_mock.expect :deploy, nil

      GCG::Deployer.stub :new, deployer_mock do
        server.config.stub :save_to_cloud, nil do
          server.stub :display_next_steps, nil do
            server.stub :prepare_dir, nil do
              server.stub :wait_until_server_accessible, mock do
                server.send :base_deploy
                mock.verify
              end
            end
          end
        end
      end
    end

    it "saves the deploy config file to GCS" do
      server = GCG::CLI::Server.new

      mock = Minitest::Mock.new
      mock.expect :call, nil
      deployer_mock = Minitest::Mock.new
      deployer_mock.expect :deploy, nil

      GCG::Deployer.stub :new, deployer_mock do
        server.config.stub :save_to_cloud, mock do
          server.stub :display_next_steps, nil do
            server.stub :prepare_dir, nil do
              server.stub :wait_until_server_accessible, nil do
                server.send :base_deploy
                mock.verify
              end
            end
          end
        end
      end
    end

    it "displays helpful tips after deploying" do
      server = GCG::CLI::Server.new

      mock = Minitest::Mock.new
      mock.expect :call, nil
      deployer_mock = Minitest::Mock.new
      deployer_mock.expect :deploy, nil

      GCG::Deployer.stub :new, deployer_mock do
        server.config.stub :save_to_cloud, nil do
          server.stub :display_next_steps, mock do
            server.stub :prepare_dir, nil do
              server.stub :wait_until_server_accessible, nil do
                server.send :base_deploy
                mock.verify
              end
            end
          end
        end
      end
    end
  end

  describe ".update" do
    it "checks if the gemserver was deployed" do
      server = GCG::CLI::Server.new
      mock = Minitest::Mock.new
      mock.expect :call, false

      server.config.stub :deployed?, mock do
        server.update
        mock.verify
      end
    end

    it "calls Deployer.new.update_gke_deploy if target platform is gke" do
      server = GCG::CLI::Server.new
      mock = Minitest::Mock.new
      mock.expect :update_gke_deploy, nil

      server.config.stub :deployed?, true do
        server.config.stub :metadata, gke do
          server.stub :prepare_dir, nil do
            server.stub :cleanup, nil do
              GCG::Deployer.stub :new, mock do
                server.update
                mock.verify
              end
            end
          end
        end
      end
    end

    it "calls base_deploy if target platform is gae" do
      server = GCG::CLI::Server.new
      mock = Minitest::Mock.new
      mock.expect :call, nil

      server.config.stub :deployed?, true do
        server.config.stub :metadata, gae do
          server.stub :base_deploy, mock do
            server.update
            mock.verify
          end
        end
      end
    end
  end

  describe ".delete" do
    it "checks if the gemserver was deployed" do
      server = GCG::CLI::Server.new
      mock = Minitest::Mock.new
      mock.expect :call, false

      server.config.stub :deployed?, mock do
        server.delete "test"
        mock.verify
      end
    end

    it "calls gcloud projects delete if full gae delete" do
      server = GCG::CLI::Server.new

      mock = Minitest::Mock.new
      mock.expect :call, true, ["gcloud projects delete test"]
      mock.expect :call, true, [String]

      server.config.stub :deployed?, true do
        server.stub :user_input, "y" do
          server.stub :system, mock do
            server.stub :del_gcs_files, nil do
              server.config.stub :delete_from_cloud, nil do
                server.delete "test"
                mock.verify
              end
            end
          end
        end
      end
    end

    it "deletes gcs files on a partial gae delete" do
      server = GCG::CLI::Server.new

      mock = Minitest::Mock.new
      mock.expect :call, nil

      server.config.stub :deployed?, true do
        server.stub :user_input, "n" do
          server.stub :system, true do
            server.stub :del_gcs_files, mock do
              server.config.stub :delete_from_cloud, nil do
                server.delete "bob"
                mock.verify
              end
            end
          end
        end
      end
    end

    it "deletes the deployment config file on gcs if partial gae delete" do
      server = GCG::CLI::Server.new

      mock = Minitest::Mock.new
      mock.expect :call, nil

      server.config.stub :deployed?, true do
        server.stub :user_input, "n" do
          server.stub :system, true do
            server.stub :del_gcs_files, nil do
              server.config.stub :delete_from_cloud, mock do
                server.delete "bob"
                mock.verify
              end
            end
          end
        end
      end
    end

    it "prompts the user to manually disable the gae project if partial gae delete" do
      server = GCG::CLI::Server.new
      link = "https://console.cloud.google.com/appengine/settings?project=bob"

      server.config.stub :deployed?, true do
        server.stub :user_input, "n" do
          server.config.stub :delete_from_cloud, nil do
            server.stub :del_gcs_files, nil do
              server.stub :system, true do
                out = capture_io { server.delete "bob" }[0]
                assert out.include? link
              end
            end
          end
        end
      end
    end

    it "deletes gcs files on a gke delete" do
      server = GCG::CLI::Server.new

      mock = Minitest::Mock.new
      mock.expect :call, nil

      server.config.stub :deployed?, true do
        server.config.stub :metadata, gke do
          server.stub :system, true do
            server.stub :user_input, nil do
              server.config.stub :delete_from_cloud, nil do
                server.stub :del_gcs_files, mock do
                  server.delete "bob"
                  mock.verify
                end
              end
            end
          end
        end
      end
    end

    it "deletes the gemserver service, deployment, and cluster for gke" do
      server = GCG::CLI::Server.new
      img = GCG::Deployer::IMAGE_NAME
      c_name_zone = "test"

      mock = Minitest::Mock.new
      mock.expect :call, true, ["kubectl delete service #{img}"]
      mock.expect :call, true, ["kubectl delete deployment #{img}"]
      mock.expect :call, true, ["gcloud container clusters delete #{c_name_zone} -z #{c_name_zone}"]
      mock.expect :call, true, [String]

      server.config.stub :deployed?, true do
        server.config.stub :metadata, gke do
          server.stub :system, mock do
            server.stub :del_gcs_files, nil do
              server.config.stub :delete_from_cloud, nil do
                server.stub :user_input, c_name_zone do
                  server.delete "bob"
                  mock.verify
                end
              end
            end
          end
        end
      end
    end

    it "deletes the cloud sql instance" do
      server = GCG::CLI::Server.new
      inst_name = "test"
      inst_connection = "/cloudsql/a:b:#{inst_name}"
      app = {
        "beta_settings" => {
          "cloud_sql_instances" => inst_connection
        }
      }
      params = "delete #{inst_name} --project bob"

      mock = Minitest::Mock.new
      mock.expect :call, true, ["gcloud beta sql instances #{params}"]

      server.config.stub :deployed?, true do
        server.config.stub :metadata, gae do
          server.config.stub :app, app do
            server.config.stub :delete_from_cloud, nil do
              server.stub :user_input, "n" do
                server.stub :del_gcs_files, nil do
                  server.stub :system, mock do
                    server.delete "bob"
                    mock.verify
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
