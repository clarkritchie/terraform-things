#!/usr/bin/env bash
#
# Notes
#
# Important!  Bash variable references that use the common bash variable syntax of: dollar symbol open brace name close brace
# ...are "special", since Terraform will replace them
#
# To use regular shell variables, do not use that syntax, plain old $FOO is fine -- do not use $ { FOO } (without the spaces)
#
# Also Important!  This script is limited to 16384 bytes!!!  So it should be kept as thin as possible and why user_data.sh
# is copied from S3
#
# This script is copied into:  /var/lib/cloud/instance/scripts
# This script logs to: /var/log/cloud-init-output.log
#

set -e

export PATH=$PATH:/usr/local/bin

/usr/bin/hostnamectl set-hostname ${HOSTNAME}

# add these to the global environment
/usr/bin/echo ENV=${ENV} | tee -a /etc/environment
/usr/bin/echo REGION=${REGION} | tee -a /etc/environment
/usr/bin/echo CONFIG_BUCKET=${CONFIG_BUCKET} | tee -a /etc/environment
# echo these values to the environment -- these should not be trusted once the cluster is up and established
# these are really only used to ensure that only one EC2 starts the swarm and we manage how the other nodes
# join it -- in a long-running swarm, the leader and manager nodes may move around some
/usr/bin/echo LEADER=${LEADER} | tee -a /etc/environment
/usr/bin/echo MANAGER=${MANAGER} | tee -a /etc/environment
/usr/bin/echo WORKER=${WORKER} | tee -a /etc/environment

# Install the AWS CLI and other useful utilities
apt update -qq
apt install -yq zip cloud-utils
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
./aws/install

# install Docker
/usr/bin/apt-get -qq update
/usr/bin/apt-get -qq install --assume-yes ca-certificates curl gnupg

/usr/bin/install -m 0755 -d /etc/apt/keyrings
/usr/bin/curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
/usr/bin/chmod a+r /etc/apt/keyrings/docker.gpg

/usr/bin/echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && /usr/bin/echo "$VERSION_CODENAME")" stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

/usr/bin/apt-get update
# postgresql-client-common postgresql-client-14
# w
/usr/bin/apt-get install --assume-yes jq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin net-tools awscli redis-tools zip

snap install yq

/usr/sbin/usermod -aG docker ubuntu
/usr/bin/echo "Starting Docker"
/usr/bin/systemctl start docker

# ssh keys
aws s3 cp s3://${CONFIG_BUCKET}/authorized_keys ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# not sure if we need this agent or not
# install and start the cloudwatch agent (this is untested on a fresh install -- may need wget?)
# wget -q https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb -O /tmp/amazon-cloudwatch-agent.deb
# dpkg -i -E /tmp/amazon-cloudwatch-agent.deb
# systemctl start amazon-cloudwatch-agent

# copy the actual user_data.sh from S3
export HOME="/home/ubuntu"
cd $HOME

# run.sh (was run_swarm.sh) is MyCompany's custom Docker Swarm startup script
aws s3 cp s3://${CONFIG_BUCKET}/run.sh .
chown ubuntu:ubuntu run.sh
chmod 700 run.sh

# sync.sh copies the YAML file from the CONFIG_BUCKET if it has changed (or is not present)
aws s3 cp s3://${CONFIG_BUCKET}/sync.sh .
chown ubuntu:ubuntu sync.sh
chmod 700 sync.sh

# bash stuff, append MyCompany's customizations to the .bashrc
aws s3 cp s3://${CONFIG_BUCKET}/bashrc .
cp .bashrc .bashrc.bak
cat bashrc >> .bashrc && rm -f bashrc

# user_data.sh is basically a continuation of this script due to size restrictions
aws s3 cp s3://${CONFIG_BUCKET}/user_data.sh .
bash user_data.sh
