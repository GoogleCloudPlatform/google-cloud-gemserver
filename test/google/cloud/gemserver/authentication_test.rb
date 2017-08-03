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
require "tempfile"

describe Google::Cloud::Gemserver::Authentication do
  describe ".new" do
    it "sets the project property" do
      assert GCG::Authentication.new.proj == GCG::Configuration.new[:proj_id]
    end
  end

  let(:owners) { ["serviceaccount:owner_a", "user:owner_b"] }
  let(:editors) { ["serviceaccount:editor_a", "user:editor_b"] }
  let(:token) { "test-token" }
  let(:invalid_token) { "wrong-token" }

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

  describe ".gen_token" do
    it "creates and uploads a token if the user is authenticated" do
      auth = GCG::Authentication.new

      gen_mock = Minitest::Mock.new
      gen_mock.expect :call, token

      upload_mock = Minitest::Mock.new
      upload_mock.expect :call, nil, [Tempfile, "#{GCG::Configuration::TOKEN_PATH}-#{token}"]

      auth.stub :can_modify?, true do
        GCG::GCS.stub :upload, upload_mock do
          SecureRandom.stub :uuid, gen_mock do
            auth.gen_token
            gen_mock.verify
            upload_mock.verify
          end
        end
      end
    end

    it "does nothing if user is not authenticated" do
      auth = GCG::Authentication.new

      auth.stub :can_modify?, false do
        assert_nil auth.gen_token
      end
    end
  end

  describe ".delete_token" do
    it "deletes the token" do
      auth = GCG::Authentication.new

      gcs_mock = Minitest::Mock.new
      gcs_mock.expect :call, nil, ["#{GCG::Configuration::TOKEN_PATH}-#{token}"]

      auth.stub :can_modify?, true do
        GCG::GCS.stub :delete_file, gcs_mock do
          auth.delete_token token
          gcs_mock.verify
        end
      end
    end
  end

  describe ".check" do
    it "returns true if token exists and value matches" do
      auth = GCG::Authentication.new

      string_mock = Minitest::Mock.new
      string_mock.expect :string, token

      dl_mock = Minitest::Mock.new
      dl_mock.expect :download, string_mock

      file_mock = Minitest::Mock.new
      file_mock.expect :call, dl_mock, ["#{GCG::Configuration::TOKEN_PATH}-#{token}"]

      GCG::GCS.stub :on_gcs?, true do
        GCG::GCS.stub :get_file, file_mock do
          assert auth.check(token)
        end
      end
    end

    it "returns false if the token has the wrong value" do
      auth = GCG::Authentication.new

      string_mock = Minitest::Mock.new
      string_mock.expect :string, token

      dl_mock = Minitest::Mock.new
      dl_mock.expect :download, string_mock

      file_mock = Minitest::Mock.new
      file_mock.expect :call, dl_mock, ["#{GCG::Configuration::TOKEN_PATH}-#{invalid_token}"]

      GCG::GCS.stub :on_gcs?, true do
        GCG::GCS.stub :get_file, file_mock do
          refute auth.check(invalid_token)
        end
      end
    end

    it "returns false if the token does not exist" do
      auth = GCG::Authentication.new

      GCG::GCS.stub :on_gcs?, false do
        refute auth.check(token)
      end
    end
  end
end
