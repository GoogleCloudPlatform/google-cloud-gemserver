# Usage

## Deployment
1) Install the gem with `gem install google-cloud-gemserver`
2) Deploy the gemserver by running `production google-cloud-gemserver create --use-proj
[PROJECT_ID]`. This deploys the gemserver as a Google App Engine project to GCP.
In doing it, it creates a Cloud SQL instance. If you wish to use an existing
Cloud SQL instance run `google-cloud-gemserver create --use-proj [PROJECT_ID]
--use-inst [CLOUD_SQL INSTANCE NAME]`

Note: If you do not want to deploy to GCP and instead want to use the Cloud SQL
instance in dev_config.yml or sqlite3 database to run the gemserver completely
locally then prepend "APP_ENV=dev" or "APP_ENV=test" to google-cloud-gemserver
commands, accordingly. Read [running locally](running-locally.md) for more
details.

Your gemserver is now up and running!

## Pushing gems

To push a gem, simply run `gem push --key [key] [path-to-gem] --host
[gemserver-url/private]`

Here is an example:

* assume you have deployed a gemserver to a project called my-gemserver. This
  project has the following url: http://my-gemserver.appspot.com
* assume you created a key with read and write permissions called my-key (read
  more about key [here](key.md) for more information)

1) Create a new gem with `bundle gem private-gem`
2) Edit `private-gem.gemspec` such that the gem can be built and pushed to
arbitrary endpoints by removing the `spec.respond_to?` conditional.
3) Build the gem with `rake build`. This created a .gem file in pkg/ that we
will push to the gemserver.
4) Create a key (referred to as my-key) for your gemserver if you have not
already by running `google-cloud-gemserver create-key --use-proj PROJECT_ID`.
5) Push the gem to your gemserver: `gem push --key my-key
pkg/private-gem-0.1.0.gem --host http://my-gemserver.appspot.com/private`
Note the url has /private at the end; this is important otherwise pushing gems
will fail.

## Installing Gems

Note: same assumptions as above

1) Add `source "http://my-gemserver.appspot.com" to the top of your Gemfile.
This lets the gemserver fetch private gem dependencies from rubygems.org if they
are not currently cached.
2) Wrap private gems within a `source "http://my-gemserver.appspot.com/private
do" block such that private gems are fetched from that source. Again, note the
/private at the end of the url.
3) Run `bundle install`

That's all it takes to push gems to the gemserver and later install them.
