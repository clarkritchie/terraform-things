#!/usr/bin/env bash

set -e

if ! test -f .env; then
  echo ".env does not exist"
  exit 1
fi

source .env

ACTION=${1:-plan}
REGION=${2:-us-west-1}

printf "\nSelect the environment for a terraform ${ACTION} in ${REGION}.\n\n"
PS3="
Your choice: "

select env in chaos dev staging quit
do
    case $env in
        "dev")
            export ENV="dev"
            break;;
        "staging")
            export ENV="staging"
            break;;
        "quit")
            echo "Goodbye..."
            exit 0
            break;;
        *)
            export ENV="chaos"
            break;;
    esac
done

echo "Selecting workspace \"${ENV}\" for a terraform ${ACTION}"
terraform workspace select -or-create=true ${ENV}

terraform ${ACTION} -var-file env-${ENV}.tfvars ${EXTRA_ARGS}
