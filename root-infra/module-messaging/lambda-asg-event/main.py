from __future__ import print_function

import json
import os
import re

import boto3
from botocore.vendored import requests

meta_company = os.environ['META_COMPANY']
meta_project = os.environ['META_PROJECT']
env = os.environ['ENV']

slack_max_retry_count = 10
slack_url = os.environ['SLACK_WEBHOOK_URL']
slack_channel = os.environ['SLACK_WEBHOOK_CHANNEL']
slack_bot_name_asg = os.environ['SLACK_WEBHOOK_ASG_BOT_NAME']
slack_bot_emoji_asg = os.environ['SLACK_WEBHOOK_ASG_BOT_EMOJI']
slack_bot_name_cl = os.environ['SLACK_WEBHOOK_CL_BOT_NAME']
slack_bot_emoji_cl = os.environ['SLACK_WEBHOOK_CL_BOT_EMOJI']

cloudwatch_target_sns_arn = os.environ['CLOUDWATCH_TARGET_SNS_ARN']
cloudwatch_alert_region = os.environ['CLOUDWATCH_ALERT_REGION']

ASG_EVENT_LAUNCH = 'autoscaling:EC2_INSTANCE_LAUNCH'
ASG_EVENT_LAUNCH_ERR = 'autoscaling:EC2_INSTANCE_LAUNCH_ERROR'
ASG_EVENT_TERMINATE = 'autoscaling:EC2_INSTANCE_TERMINATE'
ASG_EVENT_TERMINATE_ERR = 'autoscaling:EC2_INSTANCE_TERMINATE_ERROR'

color_map = {
    ASG_EVENT_LAUNCH: 'good',
    ASG_EVENT_LAUNCH_ERR: 'danger',
    ASG_EVENT_TERMINATE: '#2e75b8',  # blue
    ASG_EVENT_TERMINATE_ERR: 'danger',
}

ALARM_POSTFIX_ROOT_DEVICE = "High_RootDiskUtil"
ALARM_POSTFIX_MEMORY = "High_MemUtil"
ALARM_POSTFIX_LOGICAL_VOLUME = "High_LVUtil"

# these variables used for display only
ALARM_TYPE_ROOT_DEVICE = "RootDiskSpaceUtilization"
ALARM_TYPE_MEMORY = "MemoryUtilization"
ALARM_TYPE_LOGICAL_VOLUME = "LogicalVolumeSpaceUtilization"


def get_asg_capacity_change(cause):
    s = re.search(r'capacity from (\w+ to \w+)', cause)
    if s:
        return s.group(0)


def report_asg_event_to_slack(sns_payload, asg_payload,
    asg_event_type, asg_name, instance_id):
    sns_event_subject = sns_payload['Subject']

    # https://api.slack.com/docs/attachments
    attachments = [{
        "text": "Details",
        "fallback": asg_payload,
        "color": color_map[asg_event_type],
        "fields": [
            {
                "title": "Capacity Change",
                "value": get_asg_capacity_change(asg_payload['Cause']),
                "short": True,
            },
            {
                "title": "Event",
                "value": asg_payload['Event'],
                "short": True,
            },
            {
                "title": "Auto Scaling Group",
                "value": asg_name,
                "short": True,
            },
            {
                "title": "Instance",
                "value": instance_id,
                "short": True,
            },
            {
                "title": "Cause",
                "value": asg_payload['Cause'],
                "short": False,
            }]
    }]

    slack_payload = {
        'text': sns_event_subject,
        'channel': slack_channel,
        'username': slack_bot_name_asg,
        'icon_emoji': slack_bot_emoji_asg,
        'attachments': attachments,
    }

    r = requests.post(slack_url, json=slack_payload)
    return r.status_code


def report_cloudwatch_api_response_to_slack(asg_name, instance_id,
    asg_event_type,
    cloudwatch_response_retry, cloudwatch_response_code,
    cloudwatch_api_action, cloudwatch_alarm_type):
    status = "Finished"
    color = "good"

    if cloudwatch_api_action == "DELETE":
        color = "#2e75b8"  # blue

    if cloudwatch_response_code != 200:
        status = "Failed"
        color = "danger"

    fallback = "{} to {} Cloudwatch Alarm: {} for {}/{} (ASG / Instance) by {}".format(
        status,
        cloudwatch_api_action,
        cloudwatch_alarm_type,
        asg_name, instance_id,
        asg_event_type)

    slack_text = "{} to {} Cloudwatch Alarm".format(status,
                                                    cloudwatch_api_action.lower())

    # https://api.slack.com/docs/attachments
    attachments = [{
        "text": "Details",
        "fallback": fallback,
        "color": color,
        "fields": [
            {
                "title": "Cloudwatch Action",
                "value": cloudwatch_api_action,
                "short": True
            },
            {
                "title": "Metric",
                "value": cloudwatch_alarm_type,
                "short": True,
            },
            {
                "title": "Auto Scaling Group",
                "value": asg_name,
                "short": True,
            },
            {
                "title": "Instance",
                "value": instance_id,
                "short": True,
            },
        ]
    }]

    if cloudwatch_response_code != 200:
        attachments[0]['fields'].append({
            "title": "Cloudwatch API Response Code",
            "value": cloudwatch_response_code,
            "short": True,
        })
        attachments[0]['fields'].append({
            "title": "Cloudwatch API Retry Count",
            "value": cloudwatch_response_retry,
            "short": True,
        })

    slack_payload = {
        'text': slack_text,
        'channel': slack_channel,
        'username': slack_bot_name_cl,
        'icon_emoji': slack_bot_emoji_cl,
        'attachments': attachments,
    }

    r = requests.post(slack_url, json=slack_payload)
    return r.status_code


def create_cloudwatch_client():
    if env == 'LOCAL':
        aws_access_key_id = os.environ['AWS_ACCESS_KEY_ID']
        aws_secret_access_key = os.environ['AWS_SECRET_ACCESS_KEY']

        return boto3.client('cloudwatch', region_name=cloudwatch_alert_region,
                            aws_access_key_id=aws_access_key_id,
                            aws_secret_access_key=aws_secret_access_key)

    # for prod deployment, lambda uses IAM role
    return boto3.client('cloudwatch', region_name=cloudwatch_alert_region)


def create_cloudwatch_alarm_name(asg_name, instance_id, postfix):
    abbr_asg_name = asg_name.replace("-", "").replace("_", "")
    alarm_name = "{}/{}-{}/{}_{}".format(meta_company,
                                         meta_project,
                                         abbr_asg_name,
                                         instance_id,
                                         postfix)

    return alarm_name


def create_cloudwatch_root_disk_alert(asg_name, instance_id):
    client = create_cloudwatch_client()

    metric_name = 'DiskSpaceUtilization'
    namespace = "System/Linux"
    file_system = "/dev/xvda1"
    mount_path = "/"
    postfix = ALARM_POSTFIX_ROOT_DEVICE

    alarm_name = create_cloudwatch_alarm_name(asg_name, instance_id, postfix)

    response = client.put_metric_alarm(
        AlarmName=alarm_name,
        AlarmDescription='',
        ActionsEnabled=True,
        OKActions=[],
        AlarmActions=[cloudwatch_target_sns_arn],
        InsufficientDataActions=[cloudwatch_target_sns_arn],
        MetricName=metric_name,
        Namespace=namespace,
        Statistic='Maximum',
        Dimensions=[
            {'Name': 'Filesystem', 'Value': file_system, },
            {'Name': 'MountPath', 'Value': mount_path, },
            {'Name': 'InstanceId', 'Value': instance_id, },
        ],
        Period=60,
        EvaluationPeriods=1,
        DatapointsToAlarm=1,
        Threshold=80,
        ComparisonOperator='GreaterThanOrEqualToThreshold',
        TreatMissingData='missing',
    )

    return response


def create_cloudwatch_logical_volume_alert(asg_name, instance_id):
    client = create_cloudwatch_client()

    metric_name = 'LogicalVolumeSpaceUtilization'
    namespace = "System/Linux"
    file_system = "/dev/xvdcz"
    mount_path = "docker-pool"
    postfix = ALARM_POSTFIX_LOGICAL_VOLUME

    alarm_name = create_cloudwatch_alarm_name(asg_name, instance_id, postfix)

    response = client.put_metric_alarm(
        AlarmName=alarm_name,
        AlarmDescription='',
        ActionsEnabled=True,
        OKActions=[],
        AlarmActions=[cloudwatch_target_sns_arn],
        InsufficientDataActions=[cloudwatch_target_sns_arn],
        MetricName=metric_name,
        Namespace=namespace,
        Statistic='Maximum',
        Dimensions=[
            {'Name': 'Filesystem', 'Value': file_system, },
            {'Name': 'MountPath', 'Value': mount_path, },
            {'Name': 'InstanceId', 'Value': instance_id, },
        ],
        Period=60,
        EvaluationPeriods=1,
        DatapointsToAlarm=1,
        Threshold=80,
        ComparisonOperator='GreaterThanOrEqualToThreshold',
        TreatMissingData='missing',
    )

    return response


def create_cloudwatch_memory_alert(asg_name, instance_id):
    client = create_cloudwatch_client()

    metric_name = 'MemoryUtilization'
    namespace = "System/Linux"
    postfix = ALARM_POSTFIX_MEMORY

    alarm_name = create_cloudwatch_alarm_name(asg_name, instance_id,
                                              postfix)

    response = client.put_metric_alarm(
        AlarmName=alarm_name,
        AlarmDescription='',
        ActionsEnabled=True,
        OKActions=[],
        AlarmActions=[cloudwatch_target_sns_arn],
        InsufficientDataActions=[cloudwatch_target_sns_arn],
        MetricName=metric_name,
        Namespace=namespace,
        Statistic='Maximum',
        Dimensions=[
            {'Name': 'InstanceId', 'Value': instance_id, },
        ],
        Period=60,
        EvaluationPeriods=1,
        DatapointsToAlarm=1,
        Threshold=80,
        ComparisonOperator='GreaterThanOrEqualToThreshold',
        TreatMissingData='missing',
    )

    return response


def delete_cloudwatch_alert(alarm_names):
    client = create_cloudwatch_client()

    response = client.delete_alarms(AlarmNames=alarm_names, )
    return response


def lambda_handler(event, context):
    sns_payload = event['Records'][0]['Sns']
    asg_payload = json.loads(sns_payload['Message'])
    asg_event_type = asg_payload['Event']
    asg_group_name = asg_payload['AutoScalingGroupName']
    ec2_instance_id = asg_payload['EC2InstanceId']

    is_ecs_asg = False
    if "ecs" in asg_group_name.lower():
        is_ecs_asg = True

    # testing variables
    # asg_group_name = "ecs-EcsInstanceLc-SAMPLE"
    # ec2_instance_id = "i-02024914910"
    # is_ecs_asg = False
    # asg_event_type = ASG_EVENT_TERMINATE
    # asg_event_type = ASG_EVENT_LAUNCH

    # report ASG event
    attempts = 0
    response_code = 0
    while attempts < slack_max_retry_count and response_code != 200:
        response_code = report_asg_event_to_slack(sns_payload, asg_payload,
                                                  asg_event_type,
                                                  asg_group_name,
                                                  ec2_instance_id)
        attempts += 1

    # create cloudwatch alarmas
    cloudwatch_response_list = []

    if asg_event_type == ASG_EVENT_LAUNCH:
        cloudwatch_api_action = "CREATE"

        if is_ecs_asg == False:
            cloudwatch_response1 = create_cloudwatch_root_disk_alert(
                asg_group_name,
                ec2_instance_id)
            cloudwatch_response2 = create_cloudwatch_memory_alert(
                asg_group_name,
                ec2_instance_id)
            cloudwatch_response_list = [
                {'response': cloudwatch_response1,
                 'alarm_type': ALARM_TYPE_ROOT_DEVICE, },
                {'response': cloudwatch_response2,
                 'alarm_type': ALARM_TYPE_MEMORY, },
            ]
        else:
            cloudwatch_response1 = create_cloudwatch_root_disk_alert(
                asg_group_name,
                ec2_instance_id)
            cloudwatch_response2 = create_cloudwatch_logical_volume_alert(
                asg_group_name,
                ec2_instance_id)

            cloudwatch_response_list = [
                {'response': cloudwatch_response1,
                 'alarm_type': ALARM_TYPE_ROOT_DEVICE, },
                {'response': cloudwatch_response2,
                 'alarm_type': ALARM_TYPE_LOGICAL_VOLUME, },
            ]

        # slack report: alarm creation
        for item in cloudwatch_response_list:
            cloudwatch_response = item['response']
            cloudwatch_alarm_type = item['alarm_type']

            meta = cloudwatch_response['ResponseMetadata']
            cloudwatch_response_retry = meta['RetryAttempts']
            cloudwatch_response_code = meta['HTTPStatusCode']

            attempts = 0
            response_code = 0
            while attempts < slack_max_retry_count and response_code != 200:
                response_code = report_cloudwatch_api_response_to_slack(
                    asg_group_name, ec2_instance_id, asg_event_type,
                    cloudwatch_response_retry,
                    cloudwatch_response_code,
                    cloudwatch_api_action,
                    cloudwatch_alarm_type)
                attempts += 1

    elif asg_event_type == ASG_EVENT_TERMINATE:
        cloudwatch_api_action = "DELETE"

        if is_ecs_asg == False:
            root_disk_alarm_name = create_cloudwatch_alarm_name(asg_group_name,
                                                                ec2_instance_id,
                                                                ALARM_POSTFIX_ROOT_DEVICE)

            memory_alarm_name = create_cloudwatch_alarm_name(asg_group_name,
                                                             ec2_instance_id,
                                                             ALARM_POSTFIX_MEMORY)

            # api call: alarm deletion
            cloudwatch_alarm_names = [root_disk_alarm_name, memory_alarm_name]
            cloudwatch_alarm_types = [ALARM_TYPE_ROOT_DEVICE, ALARM_TYPE_MEMORY]

        else:
            lv_alarm_name = create_cloudwatch_alarm_name(asg_group_name,
                                                         ec2_instance_id,
                                                         ALARM_POSTFIX_LOGICAL_VOLUME)

            root_disk_alarm_name = create_cloudwatch_alarm_name(asg_group_name,
                                                                ec2_instance_id,
                                                                ALARM_POSTFIX_ROOT_DEVICE)

            cloudwatch_alarm_names = [lv_alarm_name, root_disk_alarm_name]
            cloudwatch_alarm_types = [ALARM_TYPE_LOGICAL_VOLUME,
                                      ALARM_TYPE_MEMORY]

        cloudwatch_response = delete_cloudwatch_alert(cloudwatch_alarm_names)
        cloudwatch_response_meta = cloudwatch_response['ResponseMetadata']
        cloudwatch_response_retry = cloudwatch_response_meta['RetryAttempts']
        cloudwatch_response_code = cloudwatch_response_meta['HTTPStatusCode']

        # report: alarm deletion
        for cloudwatch_alarm_type in cloudwatch_alarm_types:
            attempts = 0
            response_code = 0
            while attempts < slack_max_retry_count and response_code != 200:
                response_code = report_cloudwatch_api_response_to_slack(
                    asg_group_name, ec2_instance_id, asg_event_type,
                    cloudwatch_response_retry,
                    cloudwatch_response_code,
                    cloudwatch_api_action,
                    cloudwatch_alarm_type)
                attempts += 1

    return 200


# Test locally
if __name__ == '__main__':
    event_termination_non_ecs_asg = json.loads(r"""
{
    "Records": [
        {
            "EventSource": "aws:sns",
            "EventVersion": "1.0",
            "EventSubscriptionArn": "arn:aws:sns:us-east-1:123456789123:AutoScalingNotifications:00000000-0000-0000-0000-000000000000",
            "Sns": {
                "Type": "Notification",
                "MessageId": "00000000-0000-0000-0000-000000000000",
                "TopicArn": "arn:aws:sns:us-east-1:123456789:AutoScalingNotifications",
                "Subject": "Auto Scaling: termination for group \"autoscale-group-name\"",
                "Message": "{\"Progress\":50,\"AccountId\":\"123456789123\",\"Description\":\"Terminating EC2 instance: i-00000000\",\"RequestId\":\"00000000-0000-0000-0000-000000000000\",\"EndTime\":\"2016-09-16T12:39:01.604Z\",\"AutoScalingGroupARN\":\"arn:aws:autoscaling:us-east-1:123456789:autoScalingGroup:00000000-0000-0000-0000-000000000000:autoScalingGroupName/autoscale-group-name\",\"ActivityId\":\"00000000-0000-0000-0000-000000000000\",\"StartTime\":\"2016-09-16T12:37:39.004Z\",\"Service\":\"AWS Auto Scaling\",\"Time\":\"2016-09-16T12:39:01.604Z\",\"EC2InstanceId\":\"i-00000000\",\"StatusCode\":\"InProgress\",\"StatusMessage\":\"\",\"Details\":{\"Subnet ID\":\"subnet-00000000\",\"Availability Zone\":\"us-east-1a\"},\"AutoScalingGroupName\":\"autoscale-group-name\",\"Cause\":\"At 2016-09-16T12:37:09Z a user request update of AutoScalingGroup constraints to min: 0, max: 0, desired: 0 changing the desired capacity from 1 to 0.  At 2016-09-16T12:37:38Z an instance was taken out of service in response to a difference between desired and actual capacity, shrinking the capacity from 1 to 0.  At 2016-09-16T12:37:39Z instance i-00000000 was selected for termination.\",\"Event\":\"autoscaling:EC2_INSTANCE_TERMINATE\"}",
                "Timestamp": "2016-09-16T12:39:01.661Z",
                "MessageAttributes": {}
            }
        }
    ]
}    
    """)

    # lambda_handler(event_termination_non_ecs_asg, None)
