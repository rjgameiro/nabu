#!/usr/bin/env bash

start_pwd="${PWD}"
while [[ "${PWD}" == "${HOME}"* ]]; do
    [[ -f "config/load.sh" ]] && cd "config" && source "load.sh" && break
    cd ..
done
# shellcheck disable=SC2164
cd "${start_pwd}"

[[ -z "${PROJECT}" ]] && echo "Please set the PROJECT environment variable." && exit 1
[[ -z "${OWNER}" ]] && echo "Please set the OWNER environment variable." && exit 1
[[ -z "${WORKSPACE_AZURE_PRINCIPAL}" ]] && echo "Please set the WORKSPACE_AZURE_PRINCIPAL environment variable." && exit 1
[[ -z "${AZURE_LOCATION}" ]] && echo "Please set the AZURE_LOCATION environment variable." && exit 1

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

deployment_name="${PROJECT}-${workspace}-workspace"
resource_group_name="rg-${deployment_name}"

if [ "${1}" == "deploy" ]; then

  echo "Creating Azure ${deployment_name} deployment."
  az deployment sub create \
    --name "${deployment_name}" \
    --location "${AZURE_LOCATION}" \
    --template-file "workspace.bicep" \
    --parameters \
        project="${PROJECT}" \
        principal="${WORKSPACE_AZURE_PRINCIPAL}" \
        workspace="${workspace}" \
        location="${AZURE_LOCATION}" \
        owner="${OWNER}"
  [ $? -ne 0 ] && exit 1

elif [ "${1}" == "delete" ]; then

  echo "Are you sure you want to delete the resource group ${resource_group_name}?"
  echo "This will delete Terraform State Blob Storage and associated resources."
  read -r -p "Type 'Yes' to proceed: "
  if [[ ! $REPLY =~ ^Yes$ ]]; then
    exit 1
  fi

  echo "Deleting Azure Resource Group ${resource_group_name}"
  az group delete \
    --name "${resource_group_name}" \
    --yes

fi
