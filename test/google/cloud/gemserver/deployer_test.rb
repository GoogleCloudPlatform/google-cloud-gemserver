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

describe Google::Cloud::Gemserver::Deployer do
  let(:gae) { { platform: "gae" } }
  let(:gke) { { platform: "gke" } }

  describe ".deploy" do
    it "calls deploy_to_gae if set platform is gae" do
      dep = GCG::Deployer.new
      mock = Minitest::Mock.new
      mock.expect :call, nil

      dep.config.stub :metadata, gae do
        dep.stub :deploy_to_gae, mock do
          dep.deploy
          mock.verify
        end
      end
    end

    it "calls deploy_to_gke if set platform is gke" do
      dep = GCG::Deployer.new
      mock = Minitest::Mock.new
      mock.expect :call, nil

      dep.config.stub :metadata, gke do
        dep.stub :deploy_to_gke, mock do
          dep.deploy
          mock.verify
        end
      end
    end
  end

  describe ".deploy_to_gae" do
    it "calls gcloud app deploy" do
      dep = GCG::Deployer.new
      path = "#{GCG::Configuration::SERVER_PATH}/app.yaml"

      mock = Minitest::Mock.new
      mock.expect :call, nil, ["gcloud app deploy #{path} -q"]

      dep.stub :system, mock do
        dep.send :deploy_to_gae
        mock.verify
      end
    end
  end

  describe ".deploy_to_gke" do
    it "calls deploy_gke_image" do
      dep = GCG::Deployer.new

      mock = Minitest::Mock.new
      mock.expect :call, nil, [String]

      dep.stub :update_gke_dockerfile, nil do
        dep.stub :system, nil do
          dep.stub :deploy_gke_image, mock do
            dep.send :deploy_to_gke
          end
        end
      end
    end
  end

  describe ".deploy_gke_image" do
    it "calls update_gke_deploy_config" do
      dep = GCG::Deployer.new

      mock = Minitest::Mock.new
      mock.expect :call, nil, [String]

      dep.stub :system, nil do
        dep.stub :create_cluster, nil do
          dep.stub :wait_for_pods, nil do
            dep.stub :update_gke_deploy_config, mock do
              dep.send :deploy_gke_image, "test"
              mock.verify
            end
          end
        end
      end
    end

    it "calls create_cluster" do
      dep = GCG::Deployer.new

      mock = Minitest::Mock.new
      mock.expect :call, nil

      dep.stub :system, nil do
        dep.stub :update_gke_deploy_config, nil do
          dep.stub :wait_for_pods, nil do
            dep.stub :create_cluster, mock do
              dep.send :deploy_gke_image, "test"
              mock.verify
            end
          end
        end
      end
    end

    it "calls kubectl to create and expose the service" do
      dep = GCG::Deployer.new
      file = "#{GCG::Configuration::SERVER_PATH}/deployment.yaml"
      name = GCG::Deployer::IMAGE_NAME

      mock = Minitest::Mock.new
      mock.expect :call, nil, ["kubectl create -f #{file}"]
      mock.expect :call, nil, ["kubectl expose deployment #{name} --type LoadBalancer --port 8080"]

      dep.stub :update_gke_deploy_config, nil do
        dep.stub :create_cluster, nil do
          dep.stub :wait_for_pods, nil do
            dep.stub :system, mock do
              dep.send :deploy_gke_image, "test"
              mock.verify
            end
          end
        end
      end
    end

    it "waits for the service to start up" do
      dep = GCG::Deployer.new

      mock = Minitest::Mock.new
      mock.expect :call, nil

      dep.stub :update_gke_deploy_config, nil do
        dep.stub :system, nil do
          dep.stub :create_cluster, nil do
            dep.stub :wait_for_pods, mock do
              dep.send :deploy_gke_image, "test"
              mock.verify
            end
          end
        end
      end
    end
  end

  describe ".build_docker_image" do
    it "calls update_gke_dockerfile" do
      dep = GCG::Deployer.new

      mock = Minitest::Mock.new
      mock.expect :call, nil, [String]

      dep.stub :system, nil do
        dep.stub :update_gke_dockerfile, mock do
          dep.send :build_docker_image, "/tmp" do
            mock.verify
          end
        end
      end
    end

    it "calls docker_build" do
      dep = GCG::Deployer.new
      loc = "us.gcr.io/#{dep.config[:proj_id]}/#{GCG::Deployer::IMAGE_NAME}"

      mock = Minitest::Mock.new
      mock.expect :call, nil, ["docker build -t #{loc} test"]

      dep.stub :update_gke_dockerfile, nil do
        dep.send :build_docker_image, "test" do
          Open3.stub :capture3, nil do
            dep.stub :system, mock do
              dep.send :build_docker_image, "test" do
                mock.verify
              end
            end
          end
        end
      end
    end
  end

  describe ".push_docker_image" do
    it "calls gcloud docker -- push" do
      dep = GCG::Deployer.new

      mock = Minitest::Mock.new
      mock.expect :call, nil, ["gcloud docker -- push test"]
      mock.expect :call, nil, [String]

      dep.stub :system, mock do
        dep.send :push_docker_image, "test" do
        end
        mock.verify
      end
    end

    it "calls gsutil to cleanup" do
      dep = GCG::Deployer.new

      mock = Minitest::Mock.new
      mock.expect :call, nil, [String]
      mock.expect :call, nil, [String]

      dep.stub :system, mock do
        dep.send :push_docker_image, "test" do
        end
        mock.verify
      end
    end
  end

  describe ".create_cluster" do
    it "calls gcloud for cluster creation" do
      dep = GCG::Deployer.new

      mock = Minitest::Mock.new
      mock.expect :call, nil, ["gcloud container clusters create test --zone test"]
      mock.expect :call, nil, [String]

      dep.stub :cluster_exists?, false do
        dep.stub :user_input, "test" do
          dep.stub :system, mock do
            begin
              dep.send :create_cluster
              mock.verify
            rescue RuntimeError => e
              assert_equal e.message, "Cluster creation error."
            end
          end
        end
      end
    end

    it "calls gcloud to get credentials for the cluster" do
      dep = GCG::Deployer.new

      mock = Minitest::Mock.new
      mock.expect :call, nil, ["gcloud container clusters get-credentials test --zone test"]

      dep.stub :cluster_exists?, true do
        dep.stub :user_input, "test" do
          dep.stub :system, mock do
            dep.send :create_cluster
            mock.verify
          end
        end
      end
    end
  end
end
