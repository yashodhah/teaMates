#!/bin/bash
LAB=$1

if [ -z "$LAB" ]; then
  echo "Usage: ./deploy.sh <lab-name>"
  exit 1
fi

# Replace underscores with hyphens in the LAB name
PARSED_LAB=${LAB//_/-}

# Check for a lab-specific deploy script
SCRIPT="./${LAB}/scripts/deploy.sh"
TEMPLATE_FILE_YAML="./${LAB}/main.yaml"
TEMPLATE_FILE_YML="./${LAB}/main.yml"

if [ -f "$SCRIPT" ]; then
  echo "Running deploy script for lab: $LAB (parsed as $PARSED_LAB)"
  bash "$SCRIPT" "$PARSED_LAB"
elif [ -f "$TEMPLATE_FILE_YAML" ]; then
  echo "No deploy script found for lab: $LAB. Using main.yaml by default."
  STACK_NAME="${PARSED_LAB}-stack"
  echo "Deploying stack: $STACK_NAME using template: $TEMPLATE_FILE_YAML"
  aws cloudformation deploy \
    --stack-name "$STACK_NAME" \
    --template-file "$TEMPLATE_FILE_YAML" \
    --capabilities CAPABILITY_NAMED_IAM \
    --s3-bucket "yashodhah-aws-labs-bucket" 
elif [ -f "$TEMPLATE_FILE_YML" ]; then
  echo "No deploy script found for lab: $LAB. Using main.yml by default."
  STACK_NAME="${PARSED_LAB}-stack"
  echo "Deploying stack: $STACK_NAME using template: $TEMPLATE_FILE_YML"
  aws cloudformation deploy \
    --stack-name "$STACK_NAME" \
    --template-file "$TEMPLATE_FILE_YML" \
    --capabilities CAPABILITY_NAMED_IAM \
    --s3-bucket "yashodhah-aws-labs-bucket"
else
  echo "Error: Neither a deploy script nor a main.yaml/yml file was found for lab: $LAB"
  exit 2
fi