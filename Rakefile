require "bundler/setup"
require "bundler/gem_tasks"
require "rubocop/rake_task"
require "google/cloud/gemserver"

RuboCop::RakeTask.new

desc "Run unit tests."
task :test do
  ENV["APP_ENV"] = "test"
  $LOAD_PATH.unshift "lib", "test"
  Google::Cloud::Gemserver::Configuration.new.gen_config
  Dir.glob("test/**/*_test.rb").each { |file| require_relative file }
end

desc "Run acceptance and performance tests."
task :acceptance do
  ENV["APP_ENV"] = "dev"
  check_config
  $LOAD_PATH.unshift "lib", "acceptance"
  Google::Cloud::Gemserver::Configuration.new.gen_config
  Dir.glob("acceptance/**/*_test.rb").each { |file| require_relative file }
end

desc "Run integration test."
task :integration do
  ENV["APP_ENV"] = "dev"
  check_config
  $LOAD_PATH.unshift "lib", "integration"
  Google::Cloud::Gemserver::Configuration.new.gen_config
  Dir.glob("integration/**/*_test.rb").each { |file| require_relative file }
end

def check_config
  abort "Host missing. Run again with host=[your-gemserver-url/private]" unless ENV["host"]
  abort "Key missing. Run again with key=[name-of-key in ~/.gem/credentials]" unless ENV["key"]
end
