#!/usr/bin/env bash
# This script is used to deploy the infrastructure workspace for a project.
# Essentially, it creates a role and resource group.

start_pwd="${PWD}"
while [[ "${PWD}" == "${HOME}"* ]]; do
    [[ -f "config/load.sh" ]] && cd "config" && source "load.sh" && break
    cd ..
done
# shellcheck disable=SC2164
cd "${start_pwd}"

[[ -z "${PROJECT}" ]] && echo "Please set the PROJECT environment variable." && exit 1
[[ -z "${OWNER}" ]] && echo "Please set the OWNER environment variable." && exit 1
[[ -z "${WORKSPACE_AWS_PRINCIPAL}" ]] && echo "Please set the WORKSPACE_AWS_PRINCIPAL environment variable." && exit 1
[[ -z "${AWS_REGION}" ]] && echo "Please set the AWS_REGION environment variable." && exit 1

if [ "${1}" != "deploy" -a "${1}" != "delete" ]; then
  echo "Invalid command. Please use 'deploy' or 'delete'."
  exit 1
fi

project_pascal_case="$(snake_to_pascal_case "${PROJECT}")" || exit 1
[[ -z "${PROJECT_PASCAL_CASE}" ]] && PROJECT_PASCAL_CASE="${project_pascal_case}"

if [ -z "${2}" ]; then
  echo "Please provide the workspace name in snake case as an argument."
  exit 10
elif echo "${2}" | grep -q '[^a-z0-9_]'; then
  echo "Workspace name must be in snake case '[a-z0-9_]*'."
  exit 10
else
  workspace="${2}"
fi
workspace_pascal_case="$(echo "${workspace}" | awk -F'_' '{for (i=1; i<=NF; i++) $i=toupper(substr($i,1,1)) substr($i,2)}1' OFS='')"

stack_name="${PROJECT}-${workspace}-workspace"
resource_group_name="${PROJECT_PASCAL_CASE}${workspace_pascal_case}"

if [ "${1}" == "deploy" ]; then

  echo "Deploying AWS stack ${stack_name}."
  ${COMMAND_PREFIX} aws cloudformation deploy \
    --no-cli-page  \
    --capabilities CAPABILITY_NAMED_IAM \
    --template-file workspace.yaml \
    --stack-name "${stack_name}" \
    --parameter-overrides \
        Project="${PROJECT}" \
        ProjectPascalCase="${PROJECT_PASCAL_CASE}" \
        Workspace="${workspace}" \
        WorkspacePascalCase="${workspace_pascal_case}" \
        Principal="${WORKSPACE_AWS_PRINCIPAL}" \
        Owner="${OWNER}"
  [ $? -ne 0 ] && exit 1

  echo "Deploying resource group ${resource_group_name}."
  ${COMMAND_PREFIX} aws resource-groups get-group \
    --no-cli-page \
    --group-name "${resource_group_name}" > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "Creating resource group ${resource_group_name}."
    ${COMMAND_PREFIX} aws resource-groups create-group \
      --no-cli-page \
      --name "${resource_group_name}" \
      --resource-query "{\"Type\": \"TAG_FILTERS_1_0\", \"Query\": \"{\\\"ResourceTypeFilters\\\": [\\\"AWS::AllSupported\\\"], \\\"TagFilters\\\": [{\\\"Key\\\": \\\"workspace\\\", \\\"Values\\\": [\\\"backend\\\"]}, {\\\"Key\\\": \\\"project\\\", \\\"Values\\\": [\\\"${PROJECT}\\\"]}]}\"}" > /dev/null
    [ $? -ne 0 ] && exit 1
  else
    echo "Resource group ${resource_group_name} already exists."
  fi

elif [ "${1}" == "delete" ]; then

  echo "Are you sure you want to delete the AWS stack ${stack_name}?"
  read -r -p "Type 'Yes' to proceed: "
  if [[ ! $REPLY =~ ^Yes$ ]]; then
    exit 1
  fi

  echo "Deleting resource group ${resource_group_name}."
  ${COMMAND_PREFIX} aws resource-groups delete-group \
    --no-cli-page \
    --group-name "${resource_group_name}" > /dev/null

  echo "Deleting AWS stack stack ${stack_name}."

  ${COMMAND_PREFIX} aws cloudformation delete-stack \
    --no-cli-page \
    --stack-name "${stack_name}"

fi
