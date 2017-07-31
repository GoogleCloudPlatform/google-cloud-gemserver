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
    it "calls Deployer" do
      server = GCG::CLI::Server.new
      ENV["APP_ENV"] = "production"
      mock = Minitest::Mock.new
      mock.expect :deploy, :nil

      server.config.stub :metadata, gae do
        Google::Cloud::Gemserver::Deployer.stub :new, mock do
          server.stub :prepare_dir, nil do
            server.config.stub :save_to_cloud, nil do
              server.stub :setup_default_keys, nil do
                server.deploy
                mock.verify
              end
            end
          end
        end
      end
      ENV["APP_ENV"] = "test"
    end
  end

  describe ".update" do
    it "calls deploy for gae" do
      server = GCG::CLI::Server.new
      mock_server = Minitest::Mock.new
      mock_server.expect :call, nil

      server.config.stub :metadata, gae do
        server.stub :deploy, mock_server do
          server.update "test"
          mock_server.verify
        end
      end
    end

    it "calls kubectl apply for gke" do
      server = GCG::CLI::Server.new
      mock = Minitest::Mock.new
      mock.expect :update_gke_deploy, nil

      server.config.stub :metadata, gke do
        Google::Cloud::Gemserver::Deployer.stub :new, mock do
          server.update
          mock.verify
        end
      end
    end
  end

  describe ".delete" do
    it "calls gcloud app services delete default for gae" do
      server = GCG::CLI::Server.new
      mock_server = Minitest::Mock.new
      mock_server.expect :call, nil, ["gcloud app services delete default"]
      mock_server.expect :call, nil, [String]

      server.config.stub :metadata, gae do
        server.stub :system, mock_server do
          server.delete
          mock_server.verify
        end
      end
    end

    it "calls kubectl for gke" do
      server = GCG::CLI::Server.new
      mock = Minitest::Mock.new
      name = GCG::Deployer::IMAGE_NAME
      mock.expect :call, nil, ["kubectl delete service #{name}"]
      mock.expect :call, nil, ["kubectl delete deployment #{name}"]
      mock.expect :call, nil, ["gcloud container clusters delete test -z test"]
      mock.expect :call, nil, [String]

      server.config.stub :metadata, gke do
        server.stub :user_input, "test" do
          server.stub :system, mock do
            server.delete
            mock.verify
          end
        end
      end
    end
  end
end
