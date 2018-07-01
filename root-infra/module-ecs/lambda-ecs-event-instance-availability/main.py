from __future__ import print_function

import json
import logging
import os

from botocore.vendored import requests

meta_company = os.environ['META_COMPANY']
meta_project = os.environ['META_PROJECT']
env = os.environ['ENV']
aws_region = os.environ['CURRENT_AWS_REGION']
ecs_cluster_name = os.environ['ECS_CLUSTER_NAME']

slack_max_retry_count = 10
slack_url = os.environ['SLACK_WEBHOOK_URL']
slack_channel = os.environ['SLACK_WEBHOOK_CHANNEL']
slack_bot_name = os.environ['SLACK_WEBHOOK_BOT_NAME']
slack_bot_emoji = os.environ['SLACK_WEBHOOK_BOT_EMOJI']

color_map = {
    'SUCCESS': 'good',
    'ERROR': '#ff0000', # red
    'INFO': '#2e75b8',  # blue
    'WARNING': '#f6cd37', # orange
}


def report_container_instance_change(text, color, agent_connected,
    ec2_instance_id,
    container_instance_status):
    attachments = [{
        "text": "",
        "color": color,
        "fields": [
            {
                "title": "ECS Cluster",
                "value": ecs_cluster_name,
                "short": True,
            },
            {
                "title": "EC2 Instance",
                "value": ec2_instance_id,
                "short": True
            },
            {
                "title": "Container Instance Status",
                "value": container_instance_status,
                "short": True,
            },
            {
                "title": "ECS Agent Connected",
                "value": agent_connected,
                "short": True,
            },
        ]
    }]

    return send_slack_message(text, attachments)


def send_slack_message(slack_text, attachments):
    slack_payload = {
        'text': slack_text,
        'channel': slack_channel,
        'username': slack_bot_name,
        'icon_emoji': slack_bot_emoji,
        'attachments': attachments,
    }

    attempts = 0
    response_code = 0
    while attempts < slack_max_retry_count and response_code != 200:
        response = requests.post(slack_url, json=slack_payload)
        response_code = response.status_code
        print(response_code)
        print(attempts)
        attempts += 1

    return response_code


def lambda_handler(event, context):
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)

    logging.info(json.dumps(event, indent=4, sort_keys=True))

    # validation
    event_detail_type = event['detail-type']

    if event_detail_type != 'ECS Container Instance State Change':
        logger.info(
            'Got an event but not ecs container instance event: {}'.format(
                event_detail_type))
        return 200

    event_detail = event['detail']
    event_detail_version = event_detail['version']
    agent_connected = event_detail['agentConnected']
    ec2_instance_id = event_detail['ec2InstanceId']
    container_instance_status = event_detail['status']
    container_instance_arn = event_detail['containerInstanceArn']
    container_instance_id = container_instance_arn.split('/')[1]

    # logging
    logging.info("Event: ECS Container Instance Status Change")
    logging.info("ECS Cluster: {}".format(ecs_cluster_name))
    logging.info("ECS Agent Connected: {}".format(str(agent_connected)))
    logging.info("EC2 Instance ID: {}".format(ec2_instance_id))
    logging.info("Container Instance ID: {}".format(container_instance_id))
    logging.info(
        "Container Instance Status: {}".format(container_instance_status))

    if str(event_detail_version) != "1" and container_instance_status == "ACTIVE":
        logging.info("Got ACTIVE state but drop duplicated messages. Will exit")
        return 200

    if container_instance_status == "ACTIVE":
        color = color_map['INFO']
    elif container_instance_status == "INACTIVE":
        color = color_map['ERROR']
    else:
        color = color_map['WARNING']

    # too verbose
    # if agent_connected == False:
    #     logging.info("ECS agent is disconnected.")
    #     return 200

    text = 'ECS Container Instance is {}'.format(container_instance_status)

    # report
    logging.info("Reporting ECS Status Change due to: {}".format(text))
    report_container_instance_change(text, color, str(agent_connected),
                                     ec2_instance_id,
                                     container_instance_status)

    return 200


# Test locally
if __name__ == '__main__':
    ecs_event_example_container_instance = json.loads(r"""
{
  "version": "0",
  "id": "8952ba83-7be2-4ab5-9c32-6687532d15a2",
  "detail-type": "ECS Container Instance State Change",
  "source": "aws.ecs",
  "account": "111122223333",
  "time": "2016-12-06T16:41:06Z",
  "region": "us-east-1",
  "resources": [
    "arn:aws:ecs:us-east-1:111122223333:container-instance/b54a2a04-046f-4331-9d74-3f6d7f6ca315"
  ],
  "detail": {
    "agentConnected": false,
    "attributes": [
      {
        "name": "com.amazonaws.ecs.capability.logging-driver.syslog"
      },
      {
        "name": "com.amazonaws.ecs.capability.task-iam-role-network-host"
      },
      {
        "name": "com.amazonaws.ecs.capability.logging-driver.awslogs"
      },
      {
        "name": "com.amazonaws.ecs.capability.logging-driver.json-file"
      },
      {
        "name": "com.amazonaws.ecs.capability.docker-remote-api.1.17"
      },
      {
        "name": "com.amazonaws.ecs.capability.privileged-container"
      },
      {
        "name": "com.amazonaws.ecs.capability.docker-remote-api.1.18"
      },
      {
        "name": "com.amazonaws.ecs.capability.docker-remote-api.1.19"
      },
      {
        "name": "com.amazonaws.ecs.capability.ecr-auth"
      },
      {
        "name": "com.amazonaws.ecs.capability.docker-remote-api.1.20"
      },
      {
        "name": "com.amazonaws.ecs.capability.docker-remote-api.1.21"
      },
      {
        "name": "com.amazonaws.ecs.capability.docker-remote-api.1.22"
      },
      {
        "name": "com.amazonaws.ecs.capability.docker-remote-api.1.23"
      },
      {
        "name": "com.amazonaws.ecs.capability.task-iam-role"
      }
    ],
    "clusterArn": "arn:aws:ecs:us-east-1:111122223333:cluster/default",
    "containerInstanceArn": "arn:aws:ecs:us-east-1:111122223333:container-instance/b54a2a04-046f-4331-9d74-3f6d7f6ca315",
    "ec2InstanceId": "i-f3a8506b",
    "registeredResources": [
      {
        "name": "CPU",
        "type": "INTEGER",
        "integerValue": 2048
      },
      {
        "name": "MEMORY",
        "type": "INTEGER",
        "integerValue": 3767
      },
      {
        "name": "PORTS",
        "type": "STRINGSET",
        "stringSetValue": [
          "22",
          "2376",
          "2375",
          "51678",
          "51679"
        ]
      },
      {
        "name": "PORTS_UDP",
        "type": "STRINGSET",
        "stringSetValue": []
      }
    ],
    "remainingResources": [
      {
        "name": "CPU",
        "type": "INTEGER",
        "integerValue": 1988
      },
      {
        "name": "MEMORY",
        "type": "INTEGER",
        "integerValue": 767
      },
      {
        "name": "PORTS",
        "type": "STRINGSET",
        "stringSetValue": [
          "22",
          "2376",
          "2375",
          "51678",
          "51679"
        ]
      },
      {
        "name": "PORTS_UDP",
        "type": "STRINGSET",
        "stringSetValue": []
      }
    ],
    "status": "INACTIVE",
    "version": 14801,
    "versionInfo": {
      "agentHash": "aebcbca",
      "agentVersion": "1.13.0",
      "dockerVersion": "DockerVersion: 1.11.2"
    },
    "updatedAt": "2016-12-06T16:41:06.991Z"
  }
}
    """)

    lambda_handler(ecs_event_example_container_instance, None)
