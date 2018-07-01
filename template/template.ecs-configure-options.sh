#!/bin/bash
echo ECS_CLUSTER=${ecs_cluster_name} >> /etc/ecs/ecs.config
echo ECS_ENGINE_TASK_CLEANUP_WAIT_DURATION=${ecs_task_cleanup_duration} >> /etc/ecs/ecs.config
echo ECS_IMAGE_MINIMUM_CLEANUP_AGE=${ecs_image_minimum_cleanup_age} >> /etc/ecs/ecs.config
echo ECS_AVAILABLE_LOGGING_DRIVERS="[\"json-file\",\"awslogs\"]" >> /etc/ecs/ecs.config

