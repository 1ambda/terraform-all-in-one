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
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."
export SLACK_WEBHOOK_CHANNEL=#infra-alert
export SLACK_WEBHOOK_ASG_BOT_NAME="AWS AutoScaling"
export SLACK_WEBHOOK_ASG_BOT_EMOJI=":this_is_fine:"
export SLACK_WEBHOOK_CL_BOT_NAME="AWS CloudWatch API"
export SLACK_WEBHOOK_CL_BOT_EMOJI=":this_is_fine:"

export CLOUDWATCH_TARGET_SNS_ARN="arn:aws:sns:..."
export CLOUDWATCH_ALERT_REGION="..."

export META_COMPANY="YO_COMPANY"
export META_PROJECT="MA_PROJECT"

export ENV="LOCAL"
```