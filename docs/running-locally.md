# Running the gemserver

If you want to use the project and Cloud SQL instance in config.yml, no extra
work is necessary as that is the default setting. Prepend any
`google-cloud-gemserver` command with `APP_ENV=dev` if you want to use the
project and Cloud SQL instance in dev-config.yml.

# How to run locally

Unlike the above, you normally want to run a standalone gemserver with no
reliance on backend services when you want to run a gemserver locally. To do so,
prepend `google-cloud-gemserver` commands with `APP_ENV=test`. This creates and
uses a local sqlite3 instance with the default database, username, etc. settings as
defined [here](configuration.md). All that changes is that your gemserver url
becomes "http://localhost:8080" and the sqlite3 instance is used for key/gem
storage.

## Pushing gems
Simply run `gem push --key my-key [GEM_PATH] --host
http://localhost:8080/private` while ensuring my-key is set in
~/.gem/credentials (visit the [key document](key.md) for more details)

## Downloading gems
It is the exact same as outlined in the [usage example](usage_example.md)
except the gemserver url is http://localhost:8080. For example, this will become
your Gemfile:

```
source "http://localhost:8080"
source "http://localhost:8080/private" do
  gem "gem1"
  gem "gem2"
end
```

Again, ensure bundler config knows about my-key by running:
`bundle config http://localhost:8080/private my-key` otherwise gem installation
will fail since bundler does not know about my-key for this source.
