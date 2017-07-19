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

describe Google::Cloud::Gemserver::GemstashInstaller do
  describe ".check_and_install_gemstash" do
    it "calls gemstash_detected" do
      mock = Minitest::Mock.new
      mock.expect :call, true
      GCG::GemstashInstaller.stub :gemstash_detected, mock do
        GCG::GemstashInstaller.stub :valid_gemstash, true do
          GCG::GemstashInstaller.check_and_install_gemstash
          mock.verify
        end
      end
    end

    it "calls upgrade_gemstash or install_gemstash" do
      mock = Minitest::Mock.new
      mock.expect :call, nil
      GCG::GemstashInstaller.stub :gemstash_detected, true do
        GCG::GemstashInstaller.stub :valid_gemstash, false do
          GCG::GemstashInstaller.stub :upgrade_gemstash, mock do
            GCG::GemstashInstaller.stub :uninstall_gemstash, nil do
              GCG::GemstashInstaller.stub :install_gemstash, nil do
                GCG::GemstashInstaller.check_and_install_gemstash
                mock.verify
              end
            end
          end
        end
      end
      mock.expect :call, nil
      GCG::GemstashInstaller.stub :gemstash_detected, false do
        GCG::GemstashInstaller.stub :install_gemstash, mock do
          GCG::GemstashInstaller.check_and_install_gemstash
          mock.verify
        end
      end
    end

    it "calls valid_gemstash if gemstash is installed" do
      mock = Minitest::Mock.new
      mock.expect :call, nil
      GCG::GemstashInstaller.stub :gemstash_detected, true do
        GCG::GemstashInstaller.stub :upgrade_gemstash, nil do
          GCG::GemstashInstaller.stub :valid_gemstash, mock do
            GCG::GemstashInstaller.check_and_install_gemstash
            mock.verify
          end
        end
      end
    end
  end

  describe ".gemstash_detected" do
    it "correctly checks if gemstash is installed" do
      out = `gem which gemstash`
      assert_equal !out.empty?, GCG::GemstashInstaller.gemstash_detected
    end
  end

  describe ".install_gemstash" do
    it "calls clone_repo" do
      mock = Minitest::Mock.new
      mock.expect :call, nil
      GCG::GemstashInstaller.stub :build_and_install_gem, nil do
        GCG::GemstashInstaller.stub :clone_repo, mock do
          GCG::GemstashInstaller.stub :cleanup, nil do
            GCG::GemstashInstaller.install_gemstash
            mock.verify
          end
        end
      end
    end

    it "calls build_and_install_gem" do
      mock = Minitest::Mock.new
      mock.expect :call, nil
      GCG::GemstashInstaller.stub :build_and_install_gem, mock do
        GCG::GemstashInstaller.stub :clone_repo, nil do
          GCG::GemstashInstaller.stub :cleanup, nil do
            GCG::GemstashInstaller.install_gemstash
            mock.verify
          end
        end
      end
    end

    it "calls cleanup" do
      mock = Minitest::Mock.new
      mock.expect :call, nil
      GCG::GemstashInstaller.stub :build_and_install_gem, nil do
        GCG::GemstashInstaller.stub :clone_repo, nil do
          GCG::GemstashInstaller.stub :cleanup, mock do
            GCG::GemstashInstaller.install_gemstash
            mock.verify
          end
        end
      end
    end
  end

  describe ".upgrade_gemstash" do
    it "calls uninstall_gemstash" do
      mock = Minitest::Mock.new
      mock.expect :call, nil
      GCG::GemstashInstaller.stub :uninstall_gemstash, mock do
        GCG::GemstashInstaller.stub :install_gemstash, nil do
          GCG::GemstashInstaller.upgrade_gemstash
          mock.verify
        end
      end
    end

    it "calls install_gemstash" do
      mock = Minitest::Mock.new
      mock.expect :call, nil
      GCG::GemstashInstaller.stub :install_gemstash, mock do
        GCG::GemstashInstaller.stub :uninstall_gemstash, nil do
          GCG::GemstashInstaller.upgrade_gemstash
          mock.verify
        end
      end
    end
  end

  describe ".uninstall_gemstash" do
    it "calls gem uninstall -x gemstash" do
      mock = Minitest::Mock.new
      mock.expect :call, false, ["gem uninstall -x gemstash"]
      GCG::GemstashInstaller.stub :system, mock do
        GCG::GemstashInstaller.uninstall_gemstash
        mock.verify
      end
    end
  end

  describe ".clone_repo" do
    it "calls git clone" do
      mock = Minitest::Mock.new
      mock.expect :call, false, ["git clone #{GCG::GemstashInstaller::GEM_URL}"]
      GCG::GemstashInstaller.stub :system, mock do
        GCG::GemstashInstaller.clone_repo
        mock.verify
      end
    end
  end

  describe "cleanup" do
    it "calls rm -rf gemstash" do
      mock = Minitest::Mock.new
      mock.expect :call, false, ["rm -rf gemstash"]
      GCG::GemstashInstaller.stub :system, mock do
        GCG::GemstashInstaller.cleanup
        mock.verify
      end
    end
  end
end
