#!/usr/bin/env bash
# This script is used to deploy the infrastructure for a PROJECT specific
# Terraform S3 state backend on AWS.

start_pwd="${PWD}"
while [[ "${PWD}" == "${HOME}"* ]]; do
    [[ -f "config/load.sh" ]] && cd "config" && source "load.sh" && break
    cd ..
done
# shellcheck disable=SC2164
cd "${start_pwd}"

[[ -z "${PROJECT}" ]] && echo "Please set the PROJECT environment variable." && exit 1
[[ -z "${STATE_AZURE_PRINCIPAL}" ]] && echo "Please set the STATE_AZURE_PRINCIPAL environment variable." && exit 1
[[ -z "${OWNER}" ]] && echo "Please set the OWNER environment variable." && exit 1

if [[ "${1}" != "deploy" && "${1}" != "delete" ]]; then
  echo "Invalid command. Please use 'deploy' or 'delete'."
  exit 1
fi

project_pascal_case="$(snake_to_pascal_case "${PROJECT}")" || exit 1
[[ -z "${PROJECT_PASCAL_CASE}" ]] && PROJECT_PASCAL_CASE="${project_pascal_case}"

if [[ -n "${AZURE_LOCATION}" ]]; then
  location_with_argument="--location ${AZURE_LOCATION}"
fi

deployment_name="${PROJECT}-foundation"
resource_group_name="rg-${deployment_name}"

if [[ "${1}" == "deploy" ]]; then

  echo "Creating Azure ${deployment_name} deployment."
  az deployment sub create \
    --name "${deployment_name}" \
    ${location_with_argument} \
    --template-file "state.bicep" \
    --parameters \
        project="${PROJECT}" \
        projectPascalCase="${PROJECT_PASCAL_CASE}" \
        principal="${STATE_AZURE_PRINCIPAL}" \
        owner="${OWNER}"
  [[ $? -ne 0 ]] && exit 1

elif [[ "${1}" == "delete" ]]; then

  echo "Are you sure you want to delete the resource group '${resource_group_name}'?"
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