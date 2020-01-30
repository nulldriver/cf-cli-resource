# Pipeline Examples

## update-buildpacks

Example of watching [Pivnet](https://network.pivotal.io/) for buildpack updates and then applying them to a Cloud Foundry environment.

## zero-downtime-history

[![CI Builds](https://ci.nulldriver.com/api/v1/teams/resources/pipelines/zero-downtime-history/jobs/deploy/badge)](https://ci.nulldriver.com/teams/resources/pipelines/zero-downtime-history)

Zero downtime deployments are awesome.  You get a new version of your app running on Cloud Foundry and no-one's the wiser.

Unfortunately, a lot of plugins that do this type of deployment (I'm looking at you [blue-green-deploy](https://github.com/bluemixgaragelondon/cf-blue-green-deploy), [autopilot](https://github.com/contraband/autopilot) and [puppeteer](https://cf-puppeteer.happytobi.com/)) 
actually replace the existing application with a completely new version.  This means you lose the app's history and metrics. 

The *zero-downtime-history* pipeline shows an example where you can retain the application history by taking the approach 
of pushing a "temporary" version of the app before re-deploying over the original (main) app.  The "temporary" application 
is then stopped (you could optionally delete it instead).
