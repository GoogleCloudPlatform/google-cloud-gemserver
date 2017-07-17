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
require "active_support/core_ext/file/atomic"
require "active_support/core_ext/module/aliasing"

module PatchedEnv
  ##
  # Monkey patch to support Cloud SQL as an adapter
  def db
    if config[:db_adapter] == "cloud_sql"
      connection = Sequel.connect config.database_connection_config
      Gemstash::Env.migrate connection
      connection
    else
      super
    end
  end
end

Gemstash::Env.send :prepend, PatchedEnv
