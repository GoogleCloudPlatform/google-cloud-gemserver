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
require "net/http"

describe Google::Cloud::Gemserver::CLI::Request do
  describe "Request.new" do
    it "creates an HTTP object for the gemserver" do
      bkd = GCG::CLI::Request.new "google.com"
      assert bkd.http.class == Net::HTTP
    end
  end

  describe "create_key" do
    it "calls send_req with the correct arguments" do
      bkd = GCG::CLI::Request.new "google.com"
      mock = Minitest::Mock.new
      mock.expect :call, nil, ["post", "/api/v1/key", {permissions: nil}]
      bkd.stub :send_req, mock do
        bkd.create_key
        mock.verify
      end
    end
  end

  describe "delete_key" do
    it "calls send_req with the correct arguments" do
      bkd = GCG::CLI::Request.new "google.com"
      mock = Minitest::Mock.new
      mock.expect :call, nil, ["put", "/api/v1/key", {key: "key"}]
      bkd.stub :send_req, mock do
        bkd.delete_key "key"
        mock.verify
      end
    end
  end

  describe ".stats" do
    it "calls send_req with the correct arguments" do
      bkd = GCG::CLI::Request.new "google.com"
      mock = Minitest::Mock.new
      mock.expect :call, nil, ["get", "/api/v1/stats"]
      bkd.stub :send_req, mock do
        bkd.stats
        mock.verify
      end
    end
  end
end