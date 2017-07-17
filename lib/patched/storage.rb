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

require "gemstash"
require "google/cloud/gemserver"
require "filelock"

module PatchedResource
  ##
  # Monkeypatch to delete a file from both the local file system and Google
  # Cloud Storage. Done atomically to prevent circular file syncing where
  # files never get deleted.
  #
  # @param [String] key Name of the gem to delete.
  def delete key
    file = content_filename key
    return unless File.exist?(file) && File.exist?(properties_filename)
    Filelock file do
      super
      Google::Cloud::Gemserver::GCS.delete_file file
      Google::Cloud::Gemserver::GCS.delete_file properties_filename
    end
  end
end

Gemstash::Resource.send :prepend, PatchedResource
