#!/usr/bin/env bash
# This script is used to deploy the infrastructure for a project specific
# Terraform S3 state backend on AWS.

start_pwd="${PWD}"
while [[ "${PWD}" == "${HOME}"* ]]; do
    [[ -f "config/load.sh" ]] && cd "config" && source "load.sh" && break
    cd ..
done
# shellcheck disable=SC2164
cd "${start_pwd}"

[[ -z "${PROJECT}" ]] && echo "Please set the PROJECT environment variable." && exit 1
[[ -z "${OWNER}" ]] && echo "Please set the OWNER environment variable." && exit 1
[[ -z "${STATE_AWS_PRINCIPAL}" ]] && echo "Please set the STATE_AWS_PRINCIPAL environment variable." && exit 1
[[ -z "${AWS_REGION}" ]] && echo "Please set the AWS_REGION environment variable." && exit 1

if [[ "${1}" != "deploy" && "${1}" != "delete" ]]; then
  echo "Invalid command. Please use 'deploy' or 'delete'."
  exit 1
fi

project_pascal_case="$(snake_to_pascal_case "${PROJECT}")" || exit 1
[[ -z "${PROJECT_PASCAL_CASE}" ]] && PROJECT_PASCAL_CASE="${project_pascal_case}"

stack_name="${PROJECT}-foundation"
bucket_name="${PROJECT}-terraform-state"
resource_group_name="${PROJECT_PASCAL_CASE}Foundation"

if [[ "${1}" == "deploy" ]]; then

  echo "Deploying AWS stack ${stack_name}."
  ${COMMAND_PREFIX} aws cloudformation deploy \
    --no-cli-page \
    --capabilities CAPABILITY_NAMED_IAM \
    --template-file "state.yaml" \
    --stack-name "${stack_name}" \
    --parameter-overrides \
        Project="${PROJECT}" \
        ProjectPascalCase="${PROJECT_PASCAL_CASE}" \
        Principal="${STATE_AWS_PRINCIPAL}" \
        Owner="${OWNER}"
  [[ $? -ne 0 ]] && exit 2

  printf "\nFoundationRoleArn (for Terraform state backend):\n"
  ${COMMAND_PREFIX} aws cloudformation describe-stacks \
    --stack-name "${stack_name}" \
    --query 'Stacks[0].Outputs[?OutputKey==`FoundationRoleArn`].OutputValue' \
    --output text
  printf "\n"

  echo "Deploying resource group ${resource_group_name}."
  ${COMMAND_PREFIX} aws resource-groups get-group \
    --no-cli-page \
    --group-name "${resource_group_name}" > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "Creating resource group ${resource_group_name}."
    ${COMMAND_PREFIX} aws resource-groups create-group \
      --no-cli-page \
      --name "${resource_group_name}" \
      --resource-query "{\"Type\": \"TAG_FILTERS_1_0\", \"Query\": \"{\\\"ResourceTypeFilters\\\": [\\\"AWS::AllSupported\\\"], \\\"TagFilters\\\": [{\\\"Key\\\": \\\"workspace\\\", \\\"Values\\\": [\\\"foundation\\\"]}, {\\\"Key\\\": \\\"project\\\", \\\"Values\\\": [\\\"${project_snake_case}\\\"]}]}\"}" > /dev/null
    [[ $? -ne 0 ]] && exit 3
  else
    echo "Resource group ${resource_group_name} already exists."
  fi

elif [[ "${1}" == "delete" ]]; then

  echo "Are you sure you want to delete the AWS stack '${stack_name}'?"
  echo "This will delete all objects in Terraform State S3 bucket '${bucket_name}'."
  read -r -p "Type 'Yes' to proceed: "
  if [[ ! $REPLY =~ ^Yes$ ]]; then
    exit 4
  fi

  echo "Deleting resource group ${resource_group_name}."
  ${COMMAND_PREFIX} aws resource-groups delete-group \
    --no-cli-page \
    --group-name "${resource_group_name}" > /dev/null

  echo "Deleting all objects in S3 bucket ${bucket_name}."

  existing_versions="$(${COMMAND_PREFIX} aws s3api list-object-versions \
    --no-cli-page \
    --bucket "${bucket_name}" \
    --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"
  if [[ -n "${existing_versions}" && "${existing_versions}" != *'"Objects": null'*  ]]; then
    ${COMMAND_PREFIX} aws s3api delete-objects \
      --no-cli-page \
      --bucket "${bucket_name}" \
      --delete "${existing_versions}"
  fi

  existing_markers="$(${COMMAND_PREFIX} aws s3api list-object-versions \
    --no-cli-page \
    --bucket "${bucket_name}" \
    --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}')"
  if [[ -n "${existing_markers}" && "${existing_markers}" != *'"Objects": null'*  ]]; then
    ${COMMAND_PREFIX} aws s3api delete-objects \
      --no-cli-page \
      --bucket "${bucket_name}" \
      --delete "${existing_markers}"
  fi

  echo "Deleting AWS stack stack ${stack_name}."

  ${COMMAND_PREFIX} aws cloudformation delete-stack \
    --no-cli-page \
    --stack-name "${stack_name}"

fi
