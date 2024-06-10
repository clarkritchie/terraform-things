# Unresponsive EC2

## Serial Console Access

If an EC2 instance  has gone unresponsive and you cannot `ssh` into it.  The machine appears to be Running though one or both of the AWS status / reachablility checks may have failed.

Using `i-01a566a35b9b54d14` in the `dev` environment as a fictitous example...

- Get the ubuntu user's password from SSM, e.g. `/dev/i-01a566a35b9b54d14`

- Not sure if this is required since we place our personal SSH keys on the machine when it first comes up, but it appears that in an emergency situation you can put any abitrary key onto the machine like this:

```
aws ec2-instance-connect send-serial-console-ssh-public-key \
    --instance-id i-01a566a35b9b54d14 \
    --serial-port 0 \
    --ssh-public-key file:///Users/clark/.ssh/id_rsa.pub \
    --region us-west-1
```

- Then, within 60 seconds:

```
ssh -i ~/.ssh/id_rsa i-01a566a35b9b54d14.port0@serial-console.ec2-instance-connect.us-west-1.aws
```

- Login as `ubuntu` with the password from SSM

## Force Stop

This is truly the hammer approach:

```
aws ec2 stop-instances --region us-west-1 --instance-ids i-01a566a35b9b54d14 --force
```

## Links

- https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/connect-to-serial-console.html