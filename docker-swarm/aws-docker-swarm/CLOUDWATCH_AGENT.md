
# CloudWatch Agent

This is somewhat terse notes on how to install and configure the CloudWatch agent on Ubuntu so that additional host-level metrics are reported into CloudWatch proper.

This has been added to the bootstrap/user_data workflow, with the config added to SSM from a JSON file.  However, it has not been tested in a clean environment.  It was manually configured in `dev` and `staging`.

## Install Agent

```
wget -q https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i -E ./amazon-cloudwatch-agent.deb
rm -f amazon-cloudwatch-agent.deb
sudo apt-get update && sudo apt-get install collectd --assume-yes
```

## Configure Agent

### Run the Setup Wizard Once

- This appears to only be needed once only as it generates a JSON that is stored in SSM and future installations can just use that
- This example saves the config to SSM in the `/dev/amazon-cloudwatch-agent` namespace
- New installations can pull this down, there is no need to re-run the wizard on every host

```
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard
```

### Manually Push Up a JSON Config

- See `etc/cloudwatch-agent.json`

- This is now a set to be auto-created, see the `aws_ssm_parameter` resource named `countwatch_agent_config`

- If you ever needed to manually bootstrap this/push into SSM by hand, you could:

```
AWS_PAGER="" aws ssm put-parameter \
  --name "/dev/amazon-cloudwatch-linux" \
  --type "String" \
  --value "$(cat coudwatch-agent.json)"\
  --region us-west-1
```

## Run and Debug

### Start Agent

- Note this references the config in SSM, so it will pull that down (assuming it exists)

```
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:/${ENV}/amazon-cloudwatch-linux
```

### Check Status

```
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status
```

### Set to Start on Boot

```
sudo systemctl enable amazon-cloudwatch-agent.service
```

### Check Logs

```
/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log
```

## Permissions for EC2 Role

- See "CloudWatchAgentServerPolicy" in `data.tf`

## Links

- [Installing the CloudWatch agent on EC2 instances using your agent configuration](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/install-CloudWatch-Agent-on-EC2-Instance-fleet.html)
