#!/usr/bin/env bash
#
# See comments in cp-down.sh
#

env=${1:-dev}
files=("docker-swarm-app-a.yml" "docker-swarm-app-b.yml")
for f in ${files[@]}; do
 if [ -f $f ]; then
  aws s3 cp $f s3://docker-swarm-${env}/
 fi
done