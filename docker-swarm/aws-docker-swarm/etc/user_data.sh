#!/usr/bin/env bash

#
#  Important!  This script is called user_data.sh however it's actually called by the real user_data.sh script, which is named bootstrap.sh
#

export PATH=$PATH:/usr/local/bin

source /etc/environment

LEADER_LOG=/home/ubuntu/leader.log
MANAGER_LOG=/home/ubuntu/manager.log
WORKER_LOG=/home/ubuntu/worker.log

# set a password for the ubuntu user
# apt-get install cloud-utils --assume-yes
EC2_INSTANCE_ID=$(ec2metadata --instance-id)
ubuntu_pw=$(tr -dc 'A-Za-z0-9!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~' </dev/urandom | head -c 13; echo)
echo "ubuntu:$ubuntu_pw" | /usr/sbin/chpasswd
/usr/bin/aws ssm put-parameter --overwrite --region ${REGION} --name /${ENV}/${EC2_INSTANCE_ID} --type SecureString --value $ubuntu_pw
#
# See SERIAL.md for details on how to get into the server via a serial console
#

# this step is important and is documented in Confluence, but basically in order to allow a container to assume
# the role of the EC2, we have to modify the metadata service to allow for more than 1 "hop" -- meaning we can
# query it from a container running on the EC2 itself
# see https://mycompany.atlassian.net/wiki/spaces/PROD/pages/2859499776/Assume+Role+of+EC2+from+Container
TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)
aws ec2 modify-instance-metadata-options \
    --instance-id ${INSTANCE_ID} \
    --http-put-response-hop-limit 2 \
    --http-endpoint enabled

if [ ${LEADER} == "true" ]; then
  /usr/bin/echo "Setting up Docker Swarm" >> $LEADER_LOG 2>&1
  /usr/bin/docker swarm init --advertise-addr $(ifconfig eth0 | grep inet | grep -v inet6 | awk '{print $2}') >> $LEADER_LOG 2>&1

  /usr/bin/docker swarm join-token worker > /home/ubuntu/docker_swarm 2>&1
  /usr/bin/docker swarm join-token manager >> /home/ubuntu/docker_swarm 2>&1
  /usr/bin/chown ubuntu:ubuntu /home/ubuntu/docker_swarm
  /usr/bin/chmod 400 /home/ubuntu/docker_swarm

  # parse and store the IP and token(s) in ParameterStore
  LEADER_IP=$(docker swarm join-token worker | tail -2 | grep -v -e '^$' | awk '{print $6}')

  /usr/bin/echo "LEADER_IP is $LEADER_IP"
  /usr/bin/aws ssm put-parameter --overwrite --region ${REGION} --name /${ENV}/swarm/ip/leader --type SecureString --value $LEADER_IP >> $LEADER_LOG 2>&1

  # Not using the worker right now, but leave here for good measure
  WORKER_TOKEN=$(docker swarm join-token worker --quiet)
  /usr/bin/aws ssm put-parameter --overwrite --region ${REGION} --name /${ENV}/swarm/token/worker --type SecureString --value $WORKER_TOKEN >> $LEADER_LOG 2>&1

  MANAGER_TOKEN=$(docker swarm join-token manager --quiet)
  /usr/bin/aws ssm put-parameter --overwrite --region ${REGION} --name /${ENV}/swarm/token/manager --type SecureString --value $MANAGER_TOKEN >> $LEADER_LOG 2>&1

  DH_USERNAME=$(/usr/bin/aws ssm get-parameter --region ${REGION} --with-decryption --name /${ENV}/dockerhub/username | jq --raw-output '.Parameter.Value')
  DH_PASSWORD=$(/usr/bin/aws ssm get-parameter --region ${REGION} --with-decryption --name /${ENV}/dockerhub/token | jq --raw-output '.Parameter.Value')
  /usr/bin/echo DH_USERNAME=$DH_USERNAME | tee -a /etc/environment
  /usr/bin/echo DH_PASSWORD=$DH_PASSWORD | tee -a /etc/environment

elif [ ${MANAGER} == "true" ]; then
  /usr/bin/echo "Preparing to join the Docker Swarm as a Manager" > $MANAGER_LOG 2>&1

  # this will be surely be problematic -- we have to wait for the leader node to come up
  # additional waiting is done in the loop below
  # sleep 60

  # we're going to poll ParameterStore for these 2 values
  # once they are available, this host can join the swarm
  # this may not be long enough depending on how fast (or slow)
  # the leader boots and is ready
  counter=60
  while [ "$counter" -gt 0 ]; do

      # --raw-output is to not use double quotes for the response
      # it might be easier to use --output json and then parse with jq?
      # TODO these are versioned in Parameter Store, we need to make sure this always fetches the most recent
      LEADER_IP=$(/usr/bin/aws ssm get-parameter --region ${REGION} --with-decryption --name /${ENV}/swarm/ip/leader | jq --raw-output '.Parameter.Value')
      MANAGER_TOKEN=$(/usr/bin/aws ssm get-parameter --region ${REGION} --with-decryption --name /${ENV}/swarm/token/manager | jq --raw-output '.Parameter.Value')

      /usr/bin/echo "Counter: $counter" >> $MANAGER_LOG 2>&1
      ((counter--))

      # if these values are good, we can join the Swarm
      if [ ! -z "$LEADER_IP"  ] && [ ! -z "$MANAGER_TOKEN" ]; then
        /usr/bin/echo " - $LEADER_IP"  >> $MANAGER_LOG 2>&1
        /usr/bin/echo " - $MANAGER_TOKEN"  >> $MANAGER_LOG 2>&1
        /usr/bin/echo "  docker swarm join --token $MANAGER_TOKEN $LEADER_IP" >> $MANAGER_LOG 2>&1
        /usr/bin/docker swarm join --token $MANAGER_TOKEN $LEADER_IP >> $MANAGER_LOG 2>&1
        counter=0
      fi

      /usr/bin/echo "Waiting..." >> $MANAGER_LOG 2>&1
      sleep 1
  done

else
  /usr/bin/echo "Preparing to join the Docker Swarm as Worker" > $WORKER_LOG 2>&1

  # same comments as above for the Manager
  counter=60
  while [ "$counter" -gt 0 ]; do

      # see comments above
      LEADER_IP=$(/usr/bin/aws ssm get-parameter --region ${REGION} --with-decryption --name /${ENV}/swarm/ip/leader | jq --raw-output '.Parameter.Value')
      WORKER_TOKEN=$(/usr/bin/aws ssm get-parameter --region ${REGION} --with-decryption --name /${ENV}/swarm/token/worker | jq --raw-output '.Parameter.Value')

      /usr/bin/echo "Counter: $counter" >> $WORKER_LOG 2>&1
      ((counter--))

      if [ ! -z "$LEADER_IP"  ] && [ ! -z "$WORKER_TOKEN" ]; then
        /usr/bin/echo " - $LEADER_IP"  >> $WORKER_LOG 2>&1
        /usr/bin/echo " - $WORKER_TOKEN"  >> $WORKER_TOKEN 2>&1
        /usr/bin/echo "  docker swarm join --token $WORKER_TOKEN $LEADER_IP" >> $WORKER_LOG 2>&1
        /usr/bin/docker swarm join --token $WORKER_TOKEN $LEADER_IP >> $WORKER_LOG 2>&1
        counter=0
      fi

      /usr/bin/echo "Waiting..." >> $WORKER_LOG 2>&1
      sleep 1
  done
fi

# apply patches
/usr/bin/apt-get -qq upgrade --assume-yes

# symlink to the AWS logs and user data script for convenience
ln -s /var/log/cloud-init-output.log /home/ubuntu/bootstrap.log

# this may be un-necessary -- docker login will create this but we want to
# make sure it's owned by ubuntu not root
mkdir /home/ubuntu/.docker
touch /home/ubuntu/.docker
sudo chown -R ubuntu:ubuntu /home/ubuntu/.docker

# TODO if the swarm elects a new leader, this should continue to run and work
# even as a manager, unless for some reason it's kicked out of the Swarm entirely
# crontab files usually must end with an extra line!
if [ ${LEADER} == "true" ]; then
  /usr/bin/cat <<'EOF' >> /home/ubuntu/.crontab
# MyCompany script to check the Docker Swarm YAML files and start the apps, if changed
#
# Runs Mon-Fri 6 AM Pacific to 6 PM US/Pacific, times adjusted for UTC
* 14-23,0-2 * * 1-5 /home/ubuntu/sync.sh > /home/ubuntu/sync.log 2>&1
#`
# The above entry will not run from 4 PM to 6 PM on Fridays (as that is now Saturday UTC)
* 0-2 * * 6 /home/ubuntu/sync.sh > /home/ubuntu/sync.log 2>&1

EOF
  service cron start
  crontab -u ubuntu /home/ubuntu/.crontab
fi

# CloudWatch Agent -- this is untested
# The following assumes that there is a config present in ssm:amazon-cloudwatch-linux TODO fix this
wget -q https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i -E ./amazon-cloudwatch-agent.deb
rm -f amazon-cloudwatch-agent.deb
sudo apt-get update && sudo apt-get install collectd --assume-yes
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:amazon-cloudwatch-linux