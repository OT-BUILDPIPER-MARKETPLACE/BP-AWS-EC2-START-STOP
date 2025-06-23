#!/bin/bash
source /opt/buildpiper/shell-functions/functions.sh
source /opt/buildpiper/shell-functions/log-functions.sh
source /opt/buildpiper/shell-functions/str-functions.sh
source /opt/buildpiper/shell-functions/file-functions.sh
source /opt/buildpiper/shell-functions/aws-functions.sh

if [ "$DEBUG" = true ]; then
  set -x
fi

# IAM Role Assumption
if [ "$ASSUME_OTHER_ROLE" == true ]; then
  role_output=$(aws sts assume-role --role-arn arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME --role-session-name $ROLE_SESSION_NAME)
  if [ $? -ne 0 ]; then
    logErrorMessage "❌ Failed to assume role."
    exit 1
  fi
  export AWS_ACCESS_KEY_ID=$(echo $role_output | jq -r '.Credentials.AccessKeyId')
  export AWS_SECRET_ACCESS_KEY=$(echo $role_output | jq -r '.Credentials.SecretAccessKey')
  export AWS_SESSION_TOKEN=$(echo $role_output | jq -r '.Credentials.SessionToken')
fi

# Inputs
TAG_KEY=${TAG_KEY}
TAG_VALUE=${TAG_VALUE}
ACTION=${ACTION}  # Start or Stop
NEW_INSTANCE_TYPE=${NEW_INSTANCE_TYPE}

logInfoMessage "🏷️ Filtering EC2 instances with tag [$TAG_KEY=$TAG_VALUE] for action [$ACTION]..."

INSTANCE_IDS=$(aws ec2 describe-instances \
  --filters "Name=tag:$TAG_KEY,Values=$TAG_VALUE" "Name=instance-state-name,Values=running,stopped" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text)

if [ -z "$INSTANCE_IDS" ]; then
  logInfoMessage "⚠️ No matching instances found."
  exit 0
fi

logInfoMessage "🔎 Matching Instance IDs: $INSTANCE_IDS"

FAILED=""

for id in $INSTANCE_IDS; do
  logInfoMessage "📘 Processing Instance: $id"

  if [ "$ACTION" == "Start" ]; then
    if [ -n "$NEW_INSTANCE_TYPE" ]; then
      logInfoMessage "⏹️ Stopping instance $id for resizing..."
      aws ec2 stop-instances --instance-ids "$id"
      aws ec2 wait instance-stopped --instance-ids "$id"

      logInfoMessage "🔧 Changing instance type for $id to $NEW_INSTANCE_TYPE..."
      aws ec2 modify-instance-attribute --instance-id "$id" --instance-type "{\"Value\": \"$NEW_INSTANCE_TYPE\"}"

      if [ $? -ne 0 ]; then
        logErrorMessage "❌ Failed to change instance type for $id"
        FAILED="$FAILED\\n$id - Failed to change instance type"
        continue
      fi
      logInfoMessage "✅ Instance type changed for $id"
    fi

    logInfoMessage "🔼 Starting instance $id..."
    aws ec2 start-instances --instance-ids "$id"
    aws ec2 wait instance-running --instance-ids "$id"
    FINAL_STATE=$(aws ec2 describe-instances --instance-ids "$id" --query "Reservations[0].Instances[0].State.Name" --output text)

    [[ "$FINAL_STATE" == "running" ]] && logInfoMessage "✅ $id is now running" || {
      logErrorMessage "❌ $id failed to start"
      FAILED="$FAILED\\n$id - Failed to Start"
    }

  elif [ "$ACTION" == "Stop" ]; then
    logInfoMessage "🔻 Stopping instance $id..."
    aws ec2 stop-instances --instance-ids "$id"
    aws ec2 wait instance-stopped --instance-ids "$id"
    FINAL_STATE=$(aws ec2 describe-instances --instance-ids "$id" --query "Reservations[0].Instances[0].State.Name" --output text)

    if [ "$FINAL_STATE" == "stopped" ]; then
      logInfoMessage "✅ $id is now stopped"

      if [ -n "$NEW_INSTANCE_TYPE" ]; then
        logInfoMessage "🔧 Changing instance type for $id to $NEW_INSTANCE_TYPE..."
        aws ec2 modify-instance-attribute --instance-id "$id" --instance-type "{\"Value\": \"$NEW_INSTANCE_TYPE\"}"

        if [ $? -eq 0 ]; then
          logInfoMessage "✅ Instance type changed for $id"
        else
          logErrorMessage "❌ Failed to change instance type for $id"
          FAILED="$FAILED\\n$id - Failed to change instance type"
        fi
      fi
    else
      logErrorMessage "❌ $id failed to stop (state: $FINAL_STATE)"
      FAILED="$FAILED\\n$id - Failed to Stop"
    fi
  else
    logErrorMessage "❌ Invalid ACTION. Use Start or Stop."
    exit 1
  fi
done

if [ -n "$FAILED" ]; then
  logErrorMessage "⛔ Some instance actions failed:"
  echo -e "$FAILED"
  exit 1
else
  logInfoMessage "🎉 All actions completed successfully."
fi
