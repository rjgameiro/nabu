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

project_name="${PROJECT}-${workspace}-workspace"

if [ "${1}" == "deploy" ]; then

  echo "Creating Digital Ocean project ${project_name}."

  ${COMMAND_PREFIX} doctl projects create \
    --name "${project_name}" \
    --purpose "${workspace_pascal_case} workspace for ${project_pascal_case}" \
    --environment "${workspace_pascal_case}"

elif [ "${1}" == "delete" ]; then

  echo "Are you sure you want to delete the project ${project_name}?"
  read -r -p "Type 'Yes' to proceed: "
  if [[ ! $REPLY =~ ^Yes$ ]]; then
    exit 1
  fi

  echo "Deleting Digital Ocean project ${project_name}..."
  project_id=$(${COMMAND_PREFIX} doctl projects list --format Name,ID --no-header | grep "${project_name}" | awk '{print $2}')
  if [ -z "${project_id}" ]; then
    echo "Project not found."
    exit 1
  fi
  ${COMMAND_PREFIX} doctl projects delete "${project_id}" --force

fi
