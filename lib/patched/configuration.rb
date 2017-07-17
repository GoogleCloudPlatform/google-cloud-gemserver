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

module PatchedConfiguration
  ##
  # Monkeypatch to support Cloud SQL by returning the necessary settings.
  def database_connection_config
    if self[:db_adapter] == "cloud_sql"
      { adapter: "mysql2" }.merge(self[:db_connection_options])
    else
      super
    end
  end
end

Gemstash::Configuration.send :prepend, PatchedConfiguration
