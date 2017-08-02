# Keys

## Environment
By default, key creation / deletion is done on the production environment
configuration (config.yml). This is important because your production
CloudSQL instance should be different from your development one. To ensure keys
are generated for the right environment, hence saved in the appropriate
databases, prepend commands with `APP_ENV=dev|test` otherwise the
environment will default to "production."

** Note that Cloud SQL proxy will need to be running for key generation and
deletion to work properly.

## Creating a key
There are 3 permission settings for a key:
* write (can only push gems)
* read (can only install gems)
* both (read and write)

To create a key with a desired permission, run:
`google-cloud-gemserver create-key --permissions [read|write|both] --use-proj PROJECT_ID`. By default, if the permissions argument is not given a key will be generated with both (read, write) permissions.

Note: the `create-key` command requires either the `--use-proj PROJECT_ID` flag
or the `--remote your-gemserver-url` flag, i.e. `--use-proj my-project` or `--remote
my-gemserver.appspot.com`.

If the current GCP project containing your gemserver is not the one you want
a key generated for, you can pass a "remote" option to target a specific
gemserver, i.e. `google-cloud gemserver create-key --remote
mygemserver.appspot.com`. Note that the key creation will fail if you do not
have access to the GCP project containing the gemserver.

To be able to push gems with the `gem push` command, a key must be supplied
(i.e. `gem push --key my-key`). Pushing gems will fails unless my-key has write
permissions. The gem command checks the ~/.gem/credentials file for my-key
before attempting to push your gem so ensure that an entry for your key has been
made. For example:

``` (~/.gem/credentials)
:my-key: 123abc
```

To be able to download gems with `bundle install`, my-key must have the read
permission. Bundler checks your bundler config for my-key before installing a
gem. Ensure that bundler knows to use my-key for any gem on your gemserver. This
can be done by running:
`bundler config http://[GEMSERVER-DOMAIN].com/private my-key`. For example"
`bundler config http://my-gemserver.appspot.com/private my-key`

## Deleting a key
To delete a key called my-key, run:
`google-cloud-gemserver delete-key --key my-key --use-proj PROJECT_ID`
If there is a specific gemserver you want to delete the key from (not the current
GCP project in `gcloud config`, run `google-cloud-gemserver delete-key my-key
--remote mygemserver.appspot.com`. Note that the command will only succeed if
you have access to the GCP project containing that gemserver.
