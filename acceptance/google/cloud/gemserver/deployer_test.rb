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

  let(:set_secret) {
    `kubectl create secret generic cloudsql-instance-credentials --from-file=credentials.json=#{ENV["GEMSERVER_CREDS"]}`
  }

  let(:clusters) {
    `gcloud container clusters list`
  }

  let(:cluster_created?) {
    cls = `gcloud container clusters list`.split("\n").drop(1)
    ret = false
    cls.map do |cluster|
      if cluster.split[0] == cluster_name
        ret = true
        break
      end
    end
    ret
  }

  let(:deployment_created?) {
    deps = `kubectl get deployments`.split("\n").drop(1)
    ret = false
    deps.map do |dep|
      if dep.split[0] == GCG::Deployer::IMAGE_NAME
        ret = true
        break
      end
    end
    ret
  }

  let(:delete_deployment) {
    `kubectl delete deployment #{GCG::Deployer::IMAGE_NAME}`
  }

  let(:service_exposed?) {
    svs = `kubectl get services`.split("\n").drop(1)
    ret = false
    svs.map do |service|
      info = service.split
      if info[0] == GCG::Deployer::IMAGE_NAME && info[2] != "<none>"
        ret = true
        break
      end
    end
    ret
  }

  let(:delete_service) {
    `kubectl delete service #{GCG::Deployer::IMAGE_NAME}`
  }

  describe "a GAE deployment" do
    it "deploys a new version to GAE" do
      s = Google::Cloud::Gemserver::CLI::Server.new
      s.config.stub :metadata, gae do
        s.config.stub :save_to_cloud, nil do
          s.stub :setup_default_keys, nil do
            ENV["APP_ENV"] = "production"
            initial_v  = GCG::Deployer.new.latest_gae_deploy_version
            s.deploy # calls Deployer.new.deploy
            final_v = GCG::Deployer.new.latest_gae_deploy_version
            refute_equal initial_v, final_v
            `gcloud beta app versions delete #{final_v}}`
            ENV["APP_ENV"] = "dev"
          end
        end
      end
    end
  end

  describe "a GKE deployment" do
    it "creates a cluster, deployment, and service" do
      s = Google::Cloud::Gemserver::CLI::Server.new
      set_secret

      dep = GCG::Deployer.new
      dep.stub :create_cluster, nil do
        dep.config.stub :metadata, gke do
          # TODO config file missing? fix
          s.send :prepare_dir
          dep.deploy
          assert deployment_created?
          assert service_exposed?
          delete_deployment
          delete_service
        end
      end
    end
  end

  describe "a GKE update" do
  end
end
