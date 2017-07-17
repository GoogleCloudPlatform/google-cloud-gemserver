# Authentication

## Using Service Account (recommended)
1) Visit the Google Cloud console for your project.
2) Go to the "IAM & Admin" page and select the "Service accounts" option
3) Create a service account or select an existing one
4) Create a key for a chosen service account and download it
5) Authenticate with gcloud with the service account key by running:
`gcloud auth activate-service-account --key-file [PATH TO SERVICE ACCOUNT KEY]`
6) Set your "GOOGLE_APPLICATION_CREDENTIALS" environment variable to the path to
your service account key file. For example:
`export GOOGLE_APPLICATION_CREDENTIALS=~/my-project.json`

## Using gcloud application-default
Simply run `gcloud auth application-default login` to authenticate yourself with
gcloud. This method is simpler, however, will not work well for a production
environment. It is better for running the gemserver locally.
