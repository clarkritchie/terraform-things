#!/usr/bin/env bash

# load any required values from the system's config
source /etc/environment

#
# Changes to this script, i.e. when a new app is to be uploaded, means this
# needs to be copied up to S3.
#
# The easy way  (from the terraform/docker-swarm-aws/etc dir):
# - ENV="chaos" && aws s3 cp sync.sh s3://docker-swarm-${ENV}/sync.sh
#
# The hard way (from the terraform/docker-swarm-aws dir):
# - ENV="chaos" && terraform taint aws_s3_object.sync_script && terraform apply -target aws_s3_object.sync_script -var-file ${ENV}.tfvars
#

#
# A major flaw with this right now is that this is setup to run (via cron) on the Leader and if the Leader changes
# at some point, the other nodes don't run it
#

# OS/X users!  Associative arrays do not work in Bash 3
# You must:  brew install bash
# Then run this with:  /opt/homebrew/bin/bash

# this is a little bit sloppier but you could also just:
# aws s3 cp s3://${CONFIG_BUCKET} . --recursive --exclude "*" --include "*.yml"

declare -A S3_FILES
S3_FILES["docker-app-a-swarm.yml"]="app_a"
S3_FILES["docker-app-b-swarm.yml"]="app_b"
# these are not apps but good to sync nonetheless
S3_FILES["run.sh"]=""
S3_FILES["sync.sh"]=""
S3_FILES["authorized_keys"]=""
S3_FILES["bashrc"]=""

echo "Running config sync on $(date)"

for FILE in ${!S3_FILES[@]}
do
  APP_NAME=${S3_FILES[${FILE}]}
  echo -n "Checking if ${FILE} has changed on S3... "

  # touch the file if it doesn't exist locally
  # [ ! -e ${FILE} ] && touch ${FILE} || true

  LOCAL_MD5="" # simply initialize this variable so it exists
  [ -f $FILE ] && LOCAL_MD5=($(md5sum $FILE))
  REMOTE_MD5=$(aws s3api head-object --bucket ${CONFIG_BUCKET} --key $FILE --query ETag --output text 2> /dev/null | tr -d '"')  # tr is to remove surrounding quotes

  # if REMOTE_MD5 is not an empty string and different from what is local
  if [[ -n $REMOTE_MD5 && $LOCAL_MD5 != $REMOTE_MD5 ]]; then
    echo " a change was detected"
    aws s3 cp s3://${CONFIG_BUCKET}/${FILE} .
    if [[ ! -z ${APP_NAME} ]]; then
      echo "Re-starting ${APP_NAME}"
      # restart this app in Docker Swarm
      ./run.sh ${APP_NAME}
    fi

    if [ ${FILE} == "authorized_keys" ]; then
      cp ${FILE} .ssh/
      chmod 600 .ssh/${FILE}
    fi

    if [ ${FILE} == "bashrc" ]; then
      cp ~/.bashrc.bak ~/.bashrc
      cat bashrc >> ~/.bashrc
    fi
  else
    echo " nope"
  fi
done

chmod 755 run.sh
chmod 755 sync.sh