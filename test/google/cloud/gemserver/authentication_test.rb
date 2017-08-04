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
  let(:token) { { "access_token": "test-token" } }

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

  describe ".access_token" do
    it "creates a token if the user is authorized with default credentials" do
      auth = GCG::Authentication.new

      mock = Minitest::Mock.new
      mock.expect :fetch_access_token!, token

      tmp = ENV["GOOGLE_APPLICATION_CREDENTIALS"]
      ENV["GOOGLE_APPLICATION_CREDENTIALS"] = nil

      auth.stub :can_modify?, true do
        Google::Auth.stub :get_application_default, mock do
          t = auth.access_token
          assert_equal t, token
          mock.verify
        end
      end

      ENV["GOOGLE_APPLICATION_CREDENTIALS"] = tmp
    end

    it "creates a token if the user is authorized with a service account" do
      auth = GCG::Authentication.new

      mock = Minitest::Mock.new
      mock.expect :fetch_access_token!, token

      tmp = ENV["GOOGLE_APPLICATION_CREDENTIALS"]
      ENV["GOOGLE_APPLICATION_CREDENTIALS"] = "test"

      auth.stub :can_modify?, true do
        Google::Auth::ServiceAccountCredentials.stub :make_creds, mock do
          t = auth.access_token
          assert_equal t, token
          mock.verify
        end
      end

      ENV["GOOGLE_APPLICATION_CREDENTIALS"] = tmp
    end

    it "does nothing if the user is not authenticated" do
      auth = GCG::Authentication.new

      auth.stub :can_modify?, false do
        refute auth.access_token
      end
    end
  end

  describe "validate_token" do
    it "sends a post request to the tokeninfo api with the token" do
      auth = GCG::Authentication.new

      res_mock = Minitest::Mock.new
      res_mock.expect :code, "200"

      http_mock = Minitest::Mock.new
      http_mock.expect :request, res_mock, [Net::HTTP::Post]
      http_mock.expect :use_ssl=, true, [true]

      Net::HTTP.stub :new, http_mock do
        auth.validate_token token["access_token"]
        http_mock.verify
        res_mock.verify
      end
    end
  end
end
