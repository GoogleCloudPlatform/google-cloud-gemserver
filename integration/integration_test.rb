# Copyright 2017 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

gem "minitest"
require "minitest/autorun"
require "minitest/rg"
require "minitest/focus"
require "google/cloud/gemserver"
require "fileutils"

HOST = ENV["host"]
GEM = "private-test-gem".freeze
VER  = "0.1.0".freeze
GEM_PATH = "integration/#{GEM}-#{VER}.gem".freeze
KEY = ENV["key"]
GCG = Google::Cloud::Gemserver

describe Google::Cloud::Gemserver do
  let(:gemfile) {
    gemfile = "source \"http://#{HOST}/private\" do\n" \
      "gem \"#{GEM}\"\nend"
    File.open("integration/gem_install/Gemfile", "w") do |f|
      f.write gemfile
    end
  }

  let(:reset) {
    env = Google::Cloud::Gemserver::Backend::Stats.new.send(:env)
    env.db[:versions].delete
    env.db[:rubygems].delete
  }

  let(:push) {
    url = "http://#{HOST}/private"
    `gem push --key #{KEY} #{GEM_PATH} --host #{url}`
  }

  let(:yank) {
    url = "http://#{HOST}/private"
    `RUBYGEMS_HOST=#{url} gem yank --key #{KEY} #{GEM} --version #{VER}`
  }
  let(:range) { 15..15+GCG::Backend::Key::KEY_LENGTH }

  after(:all) do
    reset
  end

  it "can push gems" do
    reset
    refute push.include?("Internal Server Error")
  end

  it "can yank gems" do
    reset
    push
    refute yank.include?("Internal Server Error")
  end

  it "can install gems" do
    gemfile
    reset
    push
    out = `cd integration/gem_install && bundle install`
    assert out.include?("Bundle complete!")
  end

  it "can get gemserver stats" do
    out = `google-cloud-gemserver stats -r #{HOST}`
    assert out.include?("Project Information")
    assert out.include?("Private Gems")
    assert out.include?("Cached Gem Dependencies")
  end

  it "can create a gemserver key" do
    # response format => Generated key: KEY
    out = `google-cloud-gemserver create-key -r #{HOST}`
    assert out.size > 16
    `google-cloud-gemserver delete-key -k #{out[range].chomp} -r #{HOST}`
    out = `google-cloud-gemserver create-key -p both -r #{HOST}`
    assert out.size > 16
    `google-cloud-gemserver delete-key -k #{out[range].chomp} -r #{HOST}`
    out = `google-cloud-gemserver create-key -p write -r #{HOST}`
    assert out.size > 16
    `google-cloud-gemserver delete-key -k #{out[range].chomp} -r #{HOST}`
    out = `google-cloud-gemserver create-key -p read -r #{HOST}`
    assert out.size > 16
    `google-cloud-gemserver delete-key -k #{out[range].chomp} -r #{HOST}`
  end

  it "can delete a gemserver key" do
    raw = `google-cloud-gemserver create-key -r #{HOST}`
    refute raw.include? "Internal server error"
    out = `google-cloud-gemserver delete-key -k #{raw[range].chomp} -r #{HOST}`
    assert out.include?("success")
  end
end
