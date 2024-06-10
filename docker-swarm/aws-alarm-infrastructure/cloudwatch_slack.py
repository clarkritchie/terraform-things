import json
from urllib.parse import urlencode
from urllib.request import Request, urlopen
from datetime import datetime
import boto3
import os

session = boto3.session.Session()

class CloudWatchAlarmParser:
    def __init__(self, msg):
        self.msg = msg
        self.timestamp_format = "%Y-%m-%dT%H:%M:%S.%f%z"
        # self.trigger = msg["Trigger"]

        if self.msg['NewStateValue'] == "ALARM":
            self.color = "danger"
        elif self.msg['NewStateValue'] == "OK":
            self.color = "good"

    def __url(self):
        return ("https://console.aws.amazon.com/cloudwatch/home?"
                + urlencode({'region': session.region_name})
                + "#alarmsV2:alarm/"
                + self.msg["AlarmName"]
                )

    # this is quickly hacked together with some bits commented out as it's unclear
    # what the exact SNS payload contains
    def slack_data(self):
        _message = {
            # 'text': '<!here|here>',  # add @here to message
            'attachments': [
                {
                    'title': ":aws: AWS CloudWatch Notification",
                    'color': self.color,
                    # see below for how to add the event's timestamp here
                    'fields': [
                        {
                            "title": "Alarm Name",
                            "value": self.msg["AlarmName"],
                            "short": True
                        },
                        {
                            'title': 'Current State',
                            'value': self.msg["NewStateValue"],
                            'short': True
                        },
                        {
                            'title': 'Link to Alarm',
                            'value': self.__url(),
                            'short': False
                        }
                        # see below for more options here
                    ]
                }
            ]
        }
        return _message

def lambda_handler(event, context):
    sns_message = json.loads(event['Records'][0]['Sns']['Message'])
    webhook_url = os.environ['SLACK_WEBHOOK_URL']
    slack_data = CloudWatchAlarmParser(sns_message).slack_data()
    slack_data["channel"] = 'eng-aws-alarms'
    request = Request(
        webhook_url,
        data=json.dumps(slack_data).encode(),
        headers={'Content-Type': 'application/json'}
        )
    response = urlopen(request)
    return {
        'statusCode': response.getcode(),
        'body': response.read().decode()
    }

if __name__ == "__main__":
    print(lambda_handler(None, None))

#
# Throw the event's timestamp onto the message at the same level as title:
#
# 'ts': datetime.strptime(
#         self.msg['StateChangeTime'],
#         self.timestamp_format
#       ).timestamp(),
#
# Other fields you might want to add to the payload:
#
# {
#     "title": "Alarm Description",
#     "value": self.msg["AlarmDescription"],
#     "short": False
# },
# {
#     "title": "Trigger",
#     "value": " ".join([
#         self.trigger["Statistic"],
#         self.trigger["MetricName"],
#         self.trigger["ComparisonOperator"],
#         str(self.trigger["Threshold"]),
#         "for",
#         str(self.trigger["EvaluationPeriods"]),
#         "period(s) of",
#         str(self.trigger["Period"]),
#         "seconds."
#     ]),
#     "short": False
# },
# {
#     'title': 'Old State',
#     'value': self.msg["OldStateValue"],
#     "short": True
# },