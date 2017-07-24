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
require "fileutils"
require "yaml"

describe Google::Cloud::Gemserver::Backend::Key do

  describe "when generating a new key with all permissions" do
    it "must have all permissions" do
      all_key =  Google::Cloud::Gemserver::Backend::Key.create_key
      puts "all_key: #{all_key}"
      wont_be_nil Gemstash::Authorization.check(all_key, "fetch")
      wont_be_nil Gemstash::Authorization.check(all_key, "push")
      wont_be_nil Gemstash::Authorization.check(all_key, "yank")
      Google::Cloud::Gemserver::Backend::Key.delete_key all_key
    end
  end

  describe "when generating a new key with only read permission" do
    it "must have the read permission" do
      fetch_key  = Google::Cloud::Gemserver::Backend::Key.create_key("read")
      puts "fetch_key: #{fetch_key}"
      wont_be_nil Gemstash::Authorization.check(fetch_key, "fetch")
      proc {Gemstash::Authorization.check(fetch_key, "push")}
        .must_raise Gemstash::NotAuthorizedError
      proc {Gemstash::Authorization.check(fetch_key, "yank")}
        .must_raise Gemstash::NotAuthorizedError
      Google::Cloud::Gemserver::Backend::Key.delete_key fetch_key
    end
  end

  describe "when deleting a key" do
    it "must succeed in deleting" do
      key_to_delete = Google::Cloud::Gemserver::Backend::Key.create_key
      wont_be_nil Google::Cloud::Gemserver::Backend::Key.delete_key key_to_delete
    end
  end

  describe "when mapping permissions from write/read to gemstash perms" do
    it "must map to fetch, yank, and push correctly" do
      MAPPING = {"write" => ["push", "yank"], "read" => ["fetch"]}
      assert MAPPING["write"],
        Google::Cloud::Gemserver::Backend::Key.send(:map_perms, "write")
      assert MAPPING["read"],
        Google::Cloud::Gemserver::Backend::Key.send(:map_perms, "read")
    end
  end
end
