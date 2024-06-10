#!/usr/bin/env bash
#
# If you want to tinker with a Docker Swarm config, any changes you may make will be overwritten when sync.sh runs
# since, at the moment, this system considers what is on s3://docker-swarm-[env] to be the source of truth
#
# Therefore, if you want to mess with something, you need to push your changes there first and then pull them back
# down onto the server, or just wait for sync.sh to run.
#
# This script is to make that easier!
# ./cp-down.sh or ./cp-down.sh staging -- will copy the files to your localhost
# edit them
# ./cp-up.sh or ./cp-up.sh staging -- will copy the files to the bucket
#

env=${1:-dev}
files=("docker-swarm-app.yml")
for f in ${files[@]}; do
  aws s3 cp s3://docker-swarm-${env}/$f .
done