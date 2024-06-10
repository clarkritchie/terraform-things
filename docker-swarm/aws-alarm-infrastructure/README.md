# AWS Alarm Infrastructure

## AWS CLI

- Example of how to send a test event using the AWS CLI and the payload below
- Note this change in the handler: `sns_message = json.loads(event['Records'][0]['Sns']['Message'])`

```
AWS_PAGER="" aws sns publish \
    --topic-arn "arn:aws:sns:us-west-1:000000000000:dev-alarm-topic" \
    --region=us-west-1 \
    --message '{"AlarmName": "TestAlarm", "AlarmDescription": "Test alarm for CloudWatch", "AWSAccountId": "000000000000", "NewStateValue": "ALARM", "NewStateReason": "Threshold Crossed: 90 >= 80", "StateChangeTime": "2022-02-23T12:00:00.000+0000", "Region": "us-east-1", "OldStateValue": "INSUFFICIENT_DATA", "Trigger": {"MetricName": "CPUUtilization", "Namespace": "AWS/RDS", "Statistic": "Average", "Unit": null, "Dimensions": [{"name": "DBInstanceIdentifier", "value": "YOUR_DB_INSTANCE_IDENTIFIER"}], "Period": 300, "EvaluationPeriods": 1, "ComparisonOperator": "GreaterThanThreshold", "Threshold": 90.0}}'
```

## Lambda

- Test from a lamda test event using the payload below
- Note this change in the handler: `sns_message = event['Records'][0]['Sns']['Message']`

```
{
  "Records": [
    {
      "EventVersion": "1.0",
      "EventSubscriptionArn": "arn:aws:sns:EXAMPLE",
      "EventSource": "aws:sns",
      "Sns": {
        "SignatureVersion": "1",
        "Timestamp": "1970-01-01T00:00:00.000Z",
        "Signature": "EXAMPLE",
        "SigningCertUrl": "EXAMPLE",
        "MessageId": "12345",
        "Message": {
          "AlarmName": "SlackAlarm",
          "NewStateValue": "OK",
          "NewStateReason": "Threshold Crossed: 1 datapoint (0.0) was not greater than or equal to the threshold (1.0)."
        },
        "MessageAttributes": {
          "Test": {
            "Type": "String",
            "Value": "TestString"
          },
          "TestBinary": {
            "Type": "Binary",
            "Value": "TestBinary"
          }
        },
        "Type": "Notification",
        "UnsubscribeUrl": "EXAMPLE",
        "TopicArn": "arn:aws:sns:EXAMPLE",
        "Subject": "TestInvoke"
      }
    }
  ]
}
```
