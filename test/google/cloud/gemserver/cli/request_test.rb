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

  let(:token) { { "access_token": "test-token" } }

  describe "Request.new" do
    it "creates an HTTP object for the gemserver" do
      req = GCG::CLI::Request.new "google.com"
      assert req.http.class == Net::HTTP
    end
  end

  describe "create_key" do
    it "calls send_req with the correct arguments" do
      req = GCG::CLI::Request.new "google.com"
      mock = Minitest::Mock.new
      mock.expect :call, nil, [Net::HTTP::Post, "/api/v1/key", {permissions: nil}]

      req.stub :send_req, mock do
        req.create_key
        mock.verify
      end
    end
  end

  describe "delete_key" do
    it "calls send_req with the correct arguments" do
      req = GCG::CLI::Request.new "google.com"
      mock = Minitest::Mock.new
      mock.expect :call, nil, [Net::HTTP::Put, "/api/v1/key", {key: "key"}]

      req.stub :send_req, mock do
        req.delete_key "key"
        mock.verify
      end
    end
  end

  describe ".stats" do
    it "calls send_req with the correct arguments" do
      req = GCG::CLI::Request.new "google.com"
      mock = Minitest::Mock.new
      mock.expect :call, nil, [Net::HTTP::Post, "/api/v1/stats"]


      req.stub :send_req, mock do
        req.stats
        mock.verify
      end
    end
  end

  describe ".send_req" do
    it "adds a token in request headers" do
      req = GCG::CLI::Request.new "google.com"

      mock = Minitest::Mock.new
      mock.expect :access_token, token

      http_mock = Minitest::Mock.new
      http_mock.expect :[]=, nil, [String, String]

      GCG::Authentication.stub :new, mock do
        req.http.stub :request, nil do
          Net::HTTP::Get.stub :new, http_mock do
            req.send :send_req, Net::HTTP::Get, "/search?query=hi"
            mock.verify
          end
        end
      end
    end
  end
end
