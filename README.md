# Google::Cloud::Gemserver

[![Build Status](https://travis-ci.org/GoogleCloudPlatform/google-cloud-gemserver.svg?branch=master)](https://travis-ci.org/GoogleCloudPlatform/google-cloud-ruby)

This gem is a tool that lets you manage, interact with, and deploy a [private gem
server](https://github.com/bundler/gemstash) to a Google Cloud Platform project.
The gemserver acts as a private gem repository for your gems similar
to how rubygems.org works with the exception that pushing and installing gems
are protected operations.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'google-cloud-gemserver'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install google-cloud-gemserver

## Usage

### Basic Prerequisites
  1) Create a Google Cloud Platform (GCP) project.
  exist. Ensure billing is enabled.
  2) Install and setup the [gcloud SDK](https://cloud.google.com/sdk/downloads). Currently, versions 161+ are supported.
  3) Authenticate gcloud by using a [service account](https://cloud.google.com/docs/authentication/getting-started) or [application default credentials](https://developers.google.com/identity/protocols/application-default-credentials).
  Using a service account is the recommended method for authentication; application default credentials should only be used for development purporses. Read this [authentication guide](docs/authentication.md) for more information.
  4) Running acceptance or performance tests requires you to have the Cloud SQL proxy running with your Cloud SQL instance. Visit this [link](https://cloud.google.com/sql/docs/mysql/connect-admin-proxy) to learn how to install and run it (steps 3 and 5 can be skipped).

### Typical Workflow
  1) Deploy a gemserver by running: `google-cloud-gemserver create --use-proj YOUR_PROJECT_ID`. This deploys the gemserver in a Google App Engine project as the default service. It also creates a new Cloud SQL instance with machine type db-f1-micro. Note that this machine type is only recommended for development / testing and is not under the CLoud SQL SLA coverage.
  2) Generate a key (referred to as my-key) by running `google-cloud-gemserver create_key` for your gemserver. By default, this generates a key with both read and write permissions. For more information about keys, read [this](docs/key.md).
  3) Add this key to your bundle config by running `bundle config http://gemserver-url.com/private/ my-key` where gemserver-url is the same as your project's url, e.g. http://my-project.appspot.com/private/. This is necessary to download gems.
  4) Add this key to your gem credentials as my-key (in ~/.gem/credentials): `:my-key: [KEY]` This is necessary to push gems (if the key has write permission).
  5) Push private gems to the gemserver as described [below](#pushing-gems).
  6) Download private gems by modifying your Gemfile as described
  [below](#fetching-gems).

### Pushing gems
  Note: ensure `my-key` has the read permission and is added in your gem
  credentials file (~/.gem/credentials)
  `gem push my-gem --key my-key --host http://my-gemserver.com/private/`

### Fetching gems
  Note: ensure `my-key` has the read permission and is set in your bundle
  config by running `bundle config http://my-gemserver.com/private/ my-key`

  1) Add `source "http://my-gemserver.com"` to the top of your Gemfile
  2) Add the following to your Gemfile:
      ```
      source "http://my-gemserver.com/private" do
        gem "my-private-gem1"
        (other private gems here)
      end
      ```
  3) Run `bundle install`

### Yanking gems
  Note: ensure `my-key` has the write permission and is added in your gem
  credentials file (~/.gem/credentials)
  `gem push my-gem --key my-key --host http://my-gemserver.com/private/`

  1) Run `gem yank --key my-key [GEM_NAME] --host
  http://my-gemserver.com/private`

  Gems can not be "unyanked" so once a gem has been yanked it cannot be pushed
  to the gemserver again with the same name and version. It can be pushed if the
  version number is changed, however.


### Gemserver commands
  * `google-cloud-gemserver config`

    Usage:
    google-cloud-gemserver config

    Displays the config the current deployed gemserver is using (if one is running)

  * `google-cloud-gemserver create`

    Usage:
    google-cloud-gemserver create

    Options:
    *  -g, [--use-proj=USE_PROJ]        # Existing project to deploy gemserver to
    *  -i, [--use-inst=USE_INST]        # Existing project to deploy gemserver to

    Creates and deploys the gem server then starts it

  * `google-cloud-gemserver create-key`

    Usage:
      google-cloud-gemserver create_key

    Options:
    *  -r, [--remote=REMOTE]            # The gemserver URL, i.e. gemserver.com
    *  -p, [--permissions=PERMISSIONS]  # Options: write, read, both. Default is
      both.
    *  -g, [--use-proj=USE_PROJ]        # The GCP project the gemserver was
       deployed to.

      Creates an authentication key

  * `google-cloud-gemserver delete_key`

    Usage:
      google-cloud-gemserver delete_key

    Options:
    *  -r, [--remote=REMOTE]            # The gemserver URL, i.e. gemserver.com
    *  -k, [--key=KEY]                  # The key to delete
    *  -g, [--use-proj=USE_PROJ]        # The GCP project the gemserver was
       deployed to.

      Deletes a given key

  * `google-cloud-gemserver delete`

    Usage:
      google-cloud-gemserver delete

    Options:
    *  -g, [--use-proj=USE_PROJ]        # Project id of GCP project the gemserver was deployed to. Warning: parent project and CloudSQL instance will also be deleted

      Delete a given gemserver

  * `google-cloud-gemserver start`

      Usage:
        google-cloud-gemserver start

      Starts the gem server. This will be run automatically after a deploy.
      Running this locally will start the gemserver locally

  * `google-cloud-gemserver stats`

    Usage:
      google-cloud-gemserver stats

    Options:
    *  -r, [--remote=REMOTE]            # The gemserver URL, i.e. gemserver.com
    *  -g, [--use-proj=USE_PROJ]        # The GCP project the gemserver was
       deployed to.

    Displays statistics on the given gemserver

  * `google-cloud-gemserver update`

    Usage:
      google-cloud-gemserver update

    Redeploys the gemserver with the current config file and google-cloud-gemserver gem version (a deploy must have succeeded for 'update' to work)

  * `google-cloud-gemserver gen_config`

    Usage:
      google-cloud-gemserver gen_config

    Generates configuration files with default values

  * `google-cloud-gemserver help`

    Usage:
      google-cloud-gemserver help [COMMAND]

    Describe available commands or one specific command

More documentation can be found in the docs [directory](docs/).

## Contributing

Detailed information can be found in [CONTRIBUTING.md](CONTRIBUTING.md).

