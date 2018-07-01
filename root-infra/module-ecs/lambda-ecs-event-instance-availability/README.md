# lambda function for ASG notifications

```bash
pyenv install 2.7.15
pyenv virtualenv 2.7.15 lambda

# development
pip install -r requirements.txt
pip install -r test-requirements.txt

# deployment
pip install -t ./lib boto3 requests
```

Inject these variables for local testing.

```bash
export ENV="LOCAL" \
    ECS_CLUSTER_NAME="COMPANY1-ECS-CLUSTER" \
    CURRENT_AWS_REGION="ap-northeast-1" \
    META_COMPANY="COMPANY1" \
    META_PROJECT="PROJECT1" \
    SLACK_WEBHOOK_URL="..." \
    SLACK_WEBHOOK_CHANNEL="#infra-alert" \
    SLACK_WEBHOOK_BOT_NAME="AWS ECS Event (Container Instance)" \
    SLACK_WEBHOOK_BOT_EMOJI=":this_is_fine:"
```