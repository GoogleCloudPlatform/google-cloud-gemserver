# How to Contribute

We'd love to accept your patches and contributions to this project. There are
just a few small guidelines you need to follow.

## Contributor License Agreement

Contributions to this project must be accompanied by a Contributor License
Agreement. You (or your employer) retain the copyright to your contribution,
this simply gives us permission to use and redistribute your contributions as
part of the project. Head over to <https://cla.developers.google.com/> to see
your current agreements on file or to sign a new one.

You generally only need to submit a CLA once, so if you've already submitted one
(even if it was for a different project), you probably don't need to do it
again.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Running tests

Note: you will need gemstash installed from
[source](https://github.com/bundler/gemstash) to run acceptance and integration
tests.

  1) Edit your app.yaml to use a separate database to run tests on otherwise
    your existing private gems can get deleted.
  2) Generate a test-key with both read/write permissions (my-test-key).
  3) To run unit tests:
    `bundle exec rake test`
  3) To run acceptance and performance tests:
    Ensure cloud_sql_proxy is running and connected to the CloudSQL instance of
    your testing gemserver (dev prefix) in app.yaml.
    `bundle exec rake test host=test-gemserver-url.com key=my-test-key`
  4) To run integration tests:
    Ensure cloud_sql_proxy is running and connected to the CloudSQL instance of
    your testing gemserver (dev prefix) in app.yaml.
    `bundle exec rake integration host=test-gemserver-url.com key=my-test-key`
