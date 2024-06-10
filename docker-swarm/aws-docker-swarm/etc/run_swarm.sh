#!/usr/bin/env bash
#
# Run the Docker Swarm Stack
#

set -e

self=$(hostname)
# docker node ls errors out on worker nodes
is_leader=$(docker node ls -f name=$self 2> /dev/null | tail -1 | grep -E "(Leader|Reachable)")
if [ ! -n "$is_leader" ]; then
    echo "This node is not the Docker Swarm leader"
    exit
fi

docker_stack_deploy () {
  echo "Deploying the stack named '${2}' now..."
  docker stack deploy \
    --with-registry-auth \
    --prune \
    --compose-file ${1} \
    ${2} 2>&1
}

HOSTNAME=$(hostname -s)
if [[ ${HOSTNAME} =~ ^.*prod.*$ ]]; then
  ENV="prod"
elif [[ ${HOSTNAME} =~ ^.*staging.*$ ]]; then
  ENV="staging"
elif [[ ${HOSTNAME} =~ ^.*chaos.*$ ]]; then
  ENV="chaos"
else
  ENV="dev"
fi

# DockerHub credentials should be here
source /etc/environment
SWARM_APP=${1:-}

if [[ -z ${DH_USERNAME} || -z ${DH_PASSWORD} ]]; then
cat <<-EOT
Missing required arguments, must pass Docker Hub username and personal access token

Use single quotes to escape special chars from the command line.

Usage:

  $0 someusername 'dckr_pat_XXXXXXXXXXXXXXXXXXXXX'

EOT
  exit 1
fi

echo ${DH_PASSWORD} | docker login --username ${DH_USERNAME} --password-stdin
echo "Preparing to deploy app named \"${SWARM_APP}\" Docker Swarm"

# create an overlay network, e.g. mycompany_dev, that allows the Docker containers on the Swarm
# to communicate with each other
OVERLAY_NETWORK="mycompany_${ENV}"
echo -n "Checking if the Docker bridge network \"${OVERLAY_NETWORK}\" already exists... "
OVERLAY_NETWORK_ID=$(docker network ls --filter name=${OVERLAY_NETWORK} --quiet)
if [ -z "${OVERLAY_NETWORK_ID}" ]; then
  echo " Overlay network does not exist"
  echo -n "Creating an overlay Docker network named \"${OVERLAY_NETWORK}\"..."
  docker network create --driver overlay --attachable --scope swarm ${OVERLAY_NETWORK}
  echo " Overlay network created"
else
  echo " Overlay network already exists"
fi

case ${SWARM_APP} in
  app_a)
    export YAML_FILE=docker-app-a-swarm.yml
    docker_stack_deploy ${YAML_FILE} app_a
    ;;
  app_b)
    export YAML_FILE=docker-app-b-swarm.yml
    docker_stack_deploy ${YAML_FILE} app_b
    ;;
  *)
    echo "Unknown Docker Swarm app name \"${SWARM_APP}\""
    ;;
esac

echo "All done"