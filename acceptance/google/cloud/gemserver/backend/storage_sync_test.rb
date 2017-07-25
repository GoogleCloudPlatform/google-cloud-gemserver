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
require "google/cloud/storage"

SS        = GCG::Backend::StorageSync

describe Google::Cloud::Gemserver::Backend::StorageSync do
  describe ".run" do
    it "calls upload_service" do
      SS.stub :try_upload, nil do
        output = capture_io { SS.run }
        assert output[0].empty? || output[0].include?("Running")
      end
    end

    it "calls download_service do" do
      SS.stub :try_download, nil do
        SS.run
        output = capture_io { SS.run }
        assert output[0].empty? || output[0].include?("Running")
      end
    end
  end

  describe ".try_upload" do
    upload_mock = Minitest::Mock.new
    upload_mock.expect :file_changed?, true, [String]
    it "calls file_changed?" do
      GCG::GCS.stub :on_gcs?, false do
        GCG::GCS.stub :upload, nil do
          File.stub :exist?, false do
            SS.stub :file_changed?, upload_mock do
              SS.try_upload "/tmp/file-that-probably-doesnt-exist"
              assert_send([upload_mock, :file_changed?, String])
            end
          end
        end
      end
    end
  end

  describe ".try_download" do
    download_mock = Minitest::Mock.new
    download_mock.expect :file_changed?, true, [String]
    it "calls file_changed?" do
      GCG::GCS.stub :sync, nil do
        File.stub :exist?, false do
          SS.try_download "/tmp/file-that-probably-doesnt-exist"
          assert_send([download_mock, :file_changed?, String])
        end
      end
    end
  end
end
