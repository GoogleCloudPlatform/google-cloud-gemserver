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
require "yaml"

describe Google::Cloud::Gemserver::Authentication do
  describe ".new" do
    it "sets the project property" do
      assert GCG::Authentication.new.proj == GCG::Configuration.new[:proj_id]
    end
  end

  let(:owners) { ["serviceaccount:owner_a", "user:owner_b"] }
  let(:editors) { ["serviceaccount:editor_a", "user:editor_b"] }

  describe ".can_modify?" do
    it "returns true iff the logged in user is the project owner" do
      auth = GCG::Authentication.new

      auth.stub :owners, owners do
        auth.stub :editors, [] do
          auth.stub :curr_user, "owner_b" do
            assert auth.can_modify?
          end
          auth.stub :curr_user, "owner_a" do
            assert auth.can_modify?
          end
          auth.stub :curr_user, "invalid_user" do
            refute auth.can_modify?
          end
        end
      end
    end

    it "returns true if the logged in user is the project editor" do
      auth = GCG::Authentication.new

      auth.stub :editors, editors do
        auth.stub :owners, [] do
          auth.stub :curr_user, "editor_a" do
            assert auth.can_modify?
          end
          auth.stub :curr_user, "editor_b" do
            assert auth.can_modify?
          end
          auth.stub :curr_user, "invalid_user" do
            refute auth.can_modify?
          end
        end
      end
    end
  end
end
