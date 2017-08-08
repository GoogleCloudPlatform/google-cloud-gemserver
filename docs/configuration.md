# Configuration

There are 4 config files, 3 are for different gemserver environments and 1 is
for the Google App Engine Flex (GAE) deployment. You only need to worry about the
GAE config file (app.yaml) as the other config files are derived from it.
1) app.yaml (GAE environment, contains all config data)
2) config.yml ("production" environment, runs on GAE)
3) dev_config.yml ("development" environment, runs on GAE - useful for acceptance
tests so gems do not get deleted)
4) test_config.yml ("testing" environment, useful for running the gemserver
locally)

These files are auto generated with default settings when any `google-cloud-gemserver` command is run. They can be explicitly created by running `google-cloud-gemserver gen-config`. The files are stored at ~/.google_cloud_gemserver by default. The config directory can be changed by setting a GEMSERVER_CONFIG_DIR environment variable to the path of your configuration directory. If that environment variable is set, it will check that directory for configuration files first before checking the default directory.

Note that the configuration directory is a convenience for gemserver deployment, it is not used by the gemserver on Google App Engine.

[Here](docs/app.yaml.example) is an example app.yaml file.

## Settings

Below are settings in the app.yaml that can be changed

* "enable_health_check" - enables Google Cloud App Engine project health checks (default false)
* "min_num_instances" - the minimum number of Google App Engine instances (autoscaled)
* "max_num_instances" - the maximum number of Google App Engine instances (autoscaled)
* "production_db_database" - production database to be used (default "mygems")
* "production_db_username" - non -root user to access the production database (default "test")
* "production_db_password" - password of the new user (default "test") that connects to the production database
* "production_db_host" - the host of the production database (default "localhost")
* "production_db_socket" - socket that the gemserver connects with to the database, for CloudSQL it is always /cloudsql/[cloud-sql-instance-connection-name]
* "production_db_adapter" - the production database adapter (default "cloud_sql")
* "dev_db_database" - development database to be used (default "mygems")
* "dev_db_username" - non -root user to access the production database (default "test")
* "dev_db_password" - password of the new user (default "test") that connects to the development database
* "dev_db_host" - the host of the development database (default "localhost")
* "dev_db_socket" - socket that the gemserver connects with to the database, for CloudSQL it is always /cloudsql/[cloud-sql-instance-connection-name]
* "dev_db_adapter" - the development database adapter (default "cloud_sql")
* "test_db_database" - test database to be used (default "mygems")
* "test_db_username" - non -root user to access the test database (default "test")
* "test_db_password" - password of the new user (default "test") that connects to the test database
* "test_db_host" - the host of the test database (default "localhost")
* "test_db_adapter" - the test database adapter (default "sqlite3")
* `gen_proj_id` - project id of the Google Cloud Platform project the gemserver was deployed to
(does not need to be set for config.yml but must be set for test_config.yml and
dev_config.yml if the database is a Cloud SQL instance)
