#!/bin/bash
LAB=$1

if [ -z "$LAB" ]; then
  echo "Usage: ./destroy.sh <lab-name>"
  exit 1
fi

# Replace underscores with hyphens in the LAB name
PARSED_LAB=${LAB//_/-}

# Check for a lab-specific destroy script
SCRIPT="./${LAB}/scripts/destroy.sh"
TEMPLATE_FILE_YAML="./${LAB}/main.yaml"
TEMPLATE_FILE_YML="./${LAB}/main.yml"

if [ -f "$SCRIPT" ]; then
  echo "Running destroy script for lab: $LAB (parsed as $PARSED_LAB)"
  bash "$SCRIPT" "$PARSED_LAB"
elif [ -f "$TEMPLATE_FILE_YAML" ]; then
  echo "No destroy script found for lab: $LAB. Using main.yaml by default."
  STACK_NAME="${PARSED_LAB}-stack"
  echo "Deleting stack: $STACK_NAME using template: $TEMPLATE_FILE_YAML"

  aws cloudformation delete-stack \
    --stack-name "$STACK_NAME"

  echo "Waiting for stack deletion to complete..."
  aws cloudformation wait stack-delete-complete \
    --stack-name "$STACK_NAME"

  echo "Stack $STACK_NAME deleted successfully."
elif [ -f "$TEMPLATE_FILE_YML" ]; then
  echo "No destroy script found for lab: $LAB. Using main.yml by default."
  STACK_NAME="${PARSED_LAB}-stack"
  echo "Deleting stack: $STACK_NAME using template: $TEMPLATE_FILE_YML"

  aws cloudformation delete-stack \
    --stack-name "$STACK_NAME"

  echo "Waiting for stack deletion to complete..."
  aws cloudformation wait stack-delete-complete \
    --stack-name "$STACK_NAME"

  echo "Stack $STACK_NAME deleted successfully."
else
  echo "Error: Neither a destroy script nor a main.yaml/yml file was found for lab: $LAB"
  exit 2
fi