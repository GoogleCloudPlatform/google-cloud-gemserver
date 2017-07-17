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

require "google/cloud/storage"
require "google/cloud/gemserver"
require "fileutils"

module Google
  module Cloud
    module Gemserver
      ##
      # # Google Cloud Storage
      #
      # Interacts with Google Cloud Storage by providing methods that upload
      # and download files to and from Google Cloud Storage.
      #
      module GCS
        ##
        # @private Fetches the project ID of the Google Cloud Platform project
        # the gemserver was deployed to.
        #
        # @return [String]
        def self.proj_id
          Google::Cloud::Gemserver::Configuration.new[:proj_id]
        end

        ##
        # @private Creates a Google::Cloud::Storage::Project object with the
        # current project ID.
        #
        # @return [Google::Cloud::Storage::Project]
        def self.cs
          return unless proj_id
          Google::Cloud::Storage.new project: proj_id, keyfile: ENV["GOOGLE_APPLICATION_CREDENTIALS"]
        end

        ##
        # @private Fetches the bucket used to store gem files for the gemserver.
        # If it does not exist a bucket is created.
        #
        # @return [Google::Cloud::Storage::Bucket]
        def self.bucket
          return unless proj_id
          bucket = cs.bucket proj_id
          bucket ? bucket : cs.create_bucket(proj_id)
        end

        ##
        # Retrieves a file from Google Cloud Storage from a project's
        # corresponding bucket.
        #
        # @param [String] file Name of the file to be retrieved.
        #
        # @return [Google::Cloud::Storage::File]
        def self.get_file file
          return unless proj_id
          bucket.file file
        end

        ##
        # Uploads a given file to a project's corresponding bucket on Google
        # Cloud Storage. A destination path of the file can be provided.
        # By default the path of the file is the same on Google Cloud Storage.
        #
        # @param [String] file Path to the file to be uploaded.
        # @param [String] dest Destination path of the file on Google Cloud
        # Storage. Optional.
        #
        # @return [Google::Cloud::Storage::File]
        def self.upload file, dest = nil
          return unless proj_id
          bucket.create_file file, dest
        end

        ##
        # Deletes a given file from Google Cloud Storage.
        #
        # @param [String] file Name of the file to be deleted.
        def self.delete_file file
          return unless proj_id
          get_file(file).delete
        end

        ##
        # @private Retrieves all files in the bucket corresponding to the
        # project the gemserver was deployed. If specified, only files with a
        # certain prefix will be retrieved.
        #
        # @param [String] prefix Prefix of the file name. Optional
        #
        # @return [Google::Cloud::Storage::File::List]
        def self.files prefix = nil
          return unless proj_id
          bucket.files prefix: prefix
        end

        ##
        # @private Checks if a file exists on both Google Cloud Storage and the
        # local file system. If the file is on Cloud Storage, but missing on
        # the file system it will be downloaded.
        #
        # @param [String] file_path File path of the file to be synced.
        #
        # @return [Boolean]
        def self.sync file_path
          return true unless proj_id
          on_cloud = on_gcs? file_path
          on_host = File.exist? file_path

          if on_cloud && !on_host
            copy_to_host file_path
            true
          elsif on_cloud && on_host
            true
          else
            false
          end
        end

        ##
        # @private Checks if a given file exists on Google Cloud Storage.
        #
        # @param [String] file_path Path of the file on Google Cloud Storage.
        #
        # @return [Boolean]
        def self.on_gcs? file_path
          return false unless proj_id
          get_file(file_path) != nil
        end

        ##
        # @private Downloads a given file from Google Cloud Storage.
        #
        # @param [String] path Path to the file.
        def self.copy_to_host path
          return unless proj_id
          file = get_file path
          folder = extract_dir path
          begin
            FileUtils.mkpath(folder) unless Dir.exist?(folder)
            file.download path
          rescue
            puts "Could not download #{file.name}." if file
          end
        end

        ##
        # @private Extracts the parent directory from a file path
        #
        # @param [String] path Path of the file.
        #
        # @return [String]
        def self.extract_dir path
          parts = path.split("/")
          parts.map { |x| x != parts.last ? x : nil }.join("/")
        end
      end
    end
  end
end
