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

require "helper"
require "fileutils"
require "benchmark"

HOST = ENV["host"]
GEM = "google-cloud-storage".freeze
VER  = "1.1.0".freeze
GEM_PATH = "integration/#{GEM}-#{VER}.gem".freeze
KEY = ENV["key"]

describe Google::Cloud::Gemserver do
  let(:gemserver_gemfile) {
    gemfile = "source \"http://#{HOST}/private\" do\n" \
      "gem \"#{GEM}\"\nend"
    File.open("integration/gem_install/Gemfile", "w") do |f|
      f.write gemfile
    end
  }

  let(:rubygems_gemfile) {
    gemfile = "source \"http://rubygems.org\" do\n" \
      "gem \"#{GEM}\"\nend"
    File.open("integration/gem_install/Gemfile", "w") do |f|
      f.write gemfile
    end
  }

  let(:reset) {
    env = Google::Cloud::Gemserver::Backend::Stats.new.send(:env)
    env.db[:versions].delete
    env.db[:rubygems].delete
    env.db[:cached_rubygems].delete
    env.db[:dependencies].delete
  }

  let(:push) {
    reset
    url = "http://#{HOST}/private"
    `gem push --key #{KEY} #{GEM_PATH} --host #{url}`
  }

  let(:yank) {
    url = "http://#{HOST}/private"
    `RUBYGEMS_HOST=#{url} gem yank --key #{KEY} #{GEM} --version #{VER}`
  }

  let(:range) { 15..GCG::Backend::Key::KEY_LENGTH }

  after(:all) do
    reset
  end

  it "can push gems" do
    Benchmark.bm(7) do |x|
      x.report("push: ") { push }
    end
  end

  it "can yank gems" do
    push
    Benchmark.bm(7) do |x|
      x.report("yank: ") { yank }
    end
  end

  it "can install gems" do
    gemserver_gemfile
    Benchmark.bm(7) do |x|
      x.report("gemserver install: ") { `cd integration/gem_install && bundle install` }
      rubygems_gemfile
      x.report("rubygems install: ") { `cd integration/gem_install && bundle install` }
    end
  end

  it "can create a gemserver key" do
    Benchmark.bm(7) do |x|
      x.report("create_key: "){ `google-cloud-gemserver create_key` }
    end
  end

  it "can delete a gemserver key" do
    raw = `google-cloud-gemserver create_key`
    key = raw[range]
    Benchmark.bm(7) do |x|
      x.report("delete_key: "){ `google-cloud-gemserver delete_key -k #{key}` }
    end
  end
end
