# coding: utf-8

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "google/cloud/gemserver/version"

Gem::Specification.new do |spec|

  spec.name          = "google-cloud-gemserver"
  spec.version       = Google::Cloud::Gemserver::VERSION
  spec.authors       = ["Arham Ahmed"]
  spec.email         = ["arhamahmed@google.com"]

  spec.summary       = "CLI to manage a private gemserver on Google App Engine"
  spec.description   = "This gem provides an easy interface to deploy and" \
                        "manage a private gem server on Google Cloud Platform."
  spec.homepage      = "https://github.com/GoogleCloudPlatform/google-cloud-gemserver"
  spec.license       = "Apache-2.0"

  spec.files         = Dir["**/*"].select do |f|
    f.match(/^(bin|lib)/) && File.file?(f)
  end + ["CONTRIBUTING.md", "README.md", "LICENSE", ".yardopts"]

  spec.executables   = "google-cloud-gemserver"
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "thor", "~> 0.19"
  spec.add_runtime_dependency "google-cloud-resource_manager", "~> 0.24"
  spec.add_runtime_dependency "google-cloud-storage", "~> 1.1.0"
  spec.add_runtime_dependency "activesupport", "~> 4.2"
  spec.add_runtime_dependency "googleauth", "~> 0.5.3"

  spec.add_development_dependency "mysql2", "~> 0.4"
  spec.add_development_dependency "filelock", "~> 1.1.1"
  spec.add_development_dependency "rake", "~> 11.0"
  spec.add_development_dependency "minitest", "~> 5.10"
  spec.add_development_dependency "minitest-autotest", "~> 1.0"
  spec.add_development_dependency "minitest-focus", "~> 1.1"
  spec.add_development_dependency "minitest-rg", "~> 5.2"
  spec.add_development_dependency "rubocop", "<= 0.49.1"
  spec.add_development_dependency "yard", "~> 0.9"
end
