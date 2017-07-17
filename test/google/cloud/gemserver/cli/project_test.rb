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

describe Google::Cloud::Gemserver::CLI::Project do
  describe "Project.new" do
    it "must set project name" do
      project = GCG::CLI::Project.new "a-project"
      assert project.proj_name == "a-project"
    end

  end

  describe ".create" do
    it "calls ResourceManager" do
      project = GCG::CLI::Project.new "test"
      mock_project = Minitest::Mock.new
      mock_project.expect :call, nil

      project.stub :project, mock_project do
        project.stub :prompt_user, nil do
          project.config.stub :update_config, nil do
            project.create
            mock_project.verify
          end
        end
      end
    end
  end
end
