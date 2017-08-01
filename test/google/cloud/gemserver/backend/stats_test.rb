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

describe Google::Cloud::Gemserver::Backend::Stats do
  describe "Stats.new" do
    it "must set the properties" do
      stats = GCG::Backend::Stats.new
      assert stats.proj.nil? || stats.proj.class == String
    end

  end

  describe ".run" do
    it "it calls log_app_description" do
      ENV["APP_ENV"] = "dev"
      stats = GCG::Backend::Stats.new
      mock = Minitest::Mock.new
      mock.expect :call, "", ["gcloud app describe --project #{stats.proj}"]
      stats.stub :run_cmd, mock do
        stats.log_app_description
      end
      mock.verify
      ENV["APP_ENV"] = "test"
    end

    it "calls log_uptime" do
      stats = GCG::Backend::Stats.new
      mock_uptime = Minitest::Mock.new
      mock_uptime.expect :call, nil

      stats.stub :project, mock_uptime do
        stats.send :log_uptime
        mock_uptime.verify
      end
    end

    it "calls log_private_gems" do
      stats = GCG::Backend::Stats.new
      mock = Minitest::Mock.new
      mock.expect :call, String
      stats.stub :db, [] do
        stats.stub :log_private_gems, mock do
          stats.send :log_private_gems
          mock.verify
        end
      end
    end

    it "calls log_cached_gems" do
      stats = GCG::Backend::Stats.new
      mock = Minitest::Mock.new
      mock.expect :call, String
      stats.stub :db, [] do
        stats.stub :log_cached_gems, mock do
          stats.send :log_cached_gems
          mock.verify
        end
      end
    end
  end
end
