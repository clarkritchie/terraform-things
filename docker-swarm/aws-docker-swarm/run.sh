#!/usr/bin/env bash

# set -e

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

# upload these files for good measure
if [[ ${ACTION} == "cp" ]]; then
  aws s3 cp etc/user_data.sh s3://docker-swarm-${ENV}/
  aws s3 cp etc/run_swarm.sh s3://docker-swarm-${ENV}/run.sh
  aws s3 cp etc/bashrc s3://docker-swarm-${ENV}/
  aws s3 cp etc/sync.sh s3://docker-swarm-${ENV}/
  aws s3 cp etc/authorized_keys s3://docker-swarm-${ENV}/
else
  echo "Selecting workspace \"${ENV}\" for a terraform ${ACTION}"
  terraform workspace select -or-create=true ${ENV}

  # TODO the bucket will need to be emptied first, including all versions

  terraform ${ACTION} -var-file env-${ENV}.tfvars ${EXTRA_ARGS}

  if [[ ${ACTION} == "destroy" ]]; then
    # Not all Parameter Store values are not created with Terraform (they are created
    # during the user_data.sh workflow) and so must be removed manually on a destroy
    echo "Cleaning up Parameter Store"
    aws ssm get-parameters-by-path --path '/dev' --region ${REGION} --recursive \
      | jq '.Parameters[].Name' \
      | xargs -L1 -I'{}' aws ssm delete-parameter --name {}

    # AWS will not let you delete a bucket that is not empty, so the terraform (below)
    # will error out unless we delete the contents first
    aws s3 rm s3://docker-swarm-${ENV} --region ${REGION} --recursive
    # bucket versioning is NOT currently enabled, so if that gets added the aboce
    # will need to change to:
    # aws s3api delete-objects --bucket docker-swarm-${ENV} \
    #   --delete "$(aws s3api list-object-versions \
    #   --bucket "docker-swarm-${ENV}" \
    #   --output=json \
    #   --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"

  fi
fi
