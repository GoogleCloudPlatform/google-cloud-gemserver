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
require "filelock"
require "digest/md5"
require "singleton"
require "concurrent"
require "forwardable"

module Google
  module Cloud
    module Gemserver
      module Backend
        ##
        # # Storage Sync
        #
        # A set of methods that manage syncing files between the local file
        # system that the gemserver runs on (a container on Google App Engine)
        # and Google Cloud Storage. By doing so, when the gemserver is restarted
        # , for whatever reason, the gems pushed to the gemserver will persist.
        # Without such a system in place all gems / files on the gemserver will
        # be lost as it runs on a container.
        #
        class StorageSync
          include Concurrent::Async
          include Singleton

          ##
          # A lock to ensure the .gemstash directory, used to store gem files, is
          # created atomically.
          DIR_LOCK = File.expand_path("~/gemstash_dir").freeze

          ##
          # Extend StorageSync such that it can be called without the
          # .instance method.
          class << self
            extend Forwardable

            ##
            # Delegate the run and download_service methods to the Singleton
            # via .instance.
            def_delegators :instance, :run, :upload_service, :download_service,
              :try_upload, :try_download, :file_changed?
          end

          ##
          # Creates an instance of the Singleton StorageSync class with a
          # background thread and asynchronous components to run methods
          # asynchronously.
          def initialize
            super
          end

          ##
          # Runs a background gem files syncing service to ensure they are up to
          # date with respect to the files on Google Cloud Storage. This allows
          # allow the gem metadata on the gemserver (in the container) to persist
          # in case of situations where the gemserver goes down.
          def run
            async.sync
          end

          ##
          # @private Runs the uploader to send updated gem files to Google Cloud
          # Storage (source of truth) then updates the rest of the gem files by
          # downloading them off Google Cloud Storage.
          def sync
            upload_service
            download_service
          end

          ##
          # @private The directory used to store gem data.
          #
          # @return [String]
          def gemstash_dir
            if ENV["APP_ENV"] == "production"
              Configuration::GEMSTASH_DIR
            else
              File.expand_path("~/.gemstash")
            end
          end

          ##
          # @private Create the directory used to store gem data.
          def prepare_dir
            Filelock DIR_LOCK do
              FileUtils.mkpath gemstash_dir
            end
          end

          ##
          # @private The uploading service that uploads gem files from the local
          # file system to Google Cloud Storage. It does not upload any cached
          # files.
          def upload_service
            puts "Running uploading service..."
            prepare_dir

            entries = Dir.glob("#{gemstash_dir}/**/*").reject do |e|
              e.include? "gem_cache"
            end
            entries.each do |e|
              try_upload e if File.file? e
            end
          end

          ##
          # @private Uploads a file to Google Cloud Storage only if the file
          # has yet to be uploaded or has a different hash from the Cloud copy.
          #
          # @param [String] file The path to the file to be uploaded.
          def try_upload file
            GCS.upload(file) unless GCS.on_gcs?(file)
            return unless file_changed?(file)
            Filelock file do
              GCS.upload file
            end
          end

          ##
          # @private The downloading service that downloads gem files from Google
          # Cloud Storage to the local file system.
          def download_service
            puts "Running downloading service..."
            prepare_dir

            files = GCS.files
            return unless files
            files.each { |file| try_download file.name }
          end

          ##
          # @private Downloads a file to the local file sytem from Google Cloud
          # Storage only if there is sufficient space and the local copy's hash
          # differs from the cloud copy's hash.
          #
          # @param [String] file Name of the file to download.
          def try_download file
            total = `df -k /`.split(" ")[11].to_f
            used = `df -k /`.split(" ")[12].to_f
            usage = used / total
            if usage < 0.95
              if File.exist? file
                Filelock(file) { GCS.sync file if file_changed? file }
              else
                GCS.copy_to_host file
              end
            else
              raise "Error downloading: disk usage at #{usage}! Increase disk space!"
            end
          end

          ##
          # @private Determines if a file on the local file system has changed
          # from the corresponding file on Google Cloud Storage, if it exists.
          #
          # @param [String] file Name of the file
          #
          # @return [Boolean]
          def file_changed? file
            return true unless File.exist? file
            return true unless GCS.get_file(file)
            gcs_md5 = GCS.get_file(file).md5
            local_md5 = Digest::MD5.file(file).base64digest
            gcs_md5 != local_md5
          end
        end
      end
    end
  end
end
