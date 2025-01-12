#!/usr/bin/env bash

start_pwd="${PWD}"
while [[ "${PWD}" == "${HOME}"* ]]; do
    [[ -f "config/load.sh" ]] && cd "config" && source "load.sh" && break
    cd ..
done
# shellcheck disable=SC2164
cd "${start_pwd}"
{
  if [[ -z "${CONFIG_LOADED}" ]]; then
    echo "config/load.sh not found"
  elif pre_flight_check; then

    unset AWS_PROFILE

    op_key_prefix="op://Development/AWS Personal Access Key"
    AWS_ACCESS_KEY_ID=$(get_from_op "required" "${op_key_prefix}/access key id") && export AWS_ACCESS_KEY_ID || unset AWS_ACCESS_KEY_ID
    AWS_SECRET_ACCESS_KEY=$(get_from_op "required" "${op_key_prefix}/secret access key") && export AWS_SECRET_ACCESS_KEY || unset AWS_SECRET_ACCESS_KEY

    op_key_prefix="op://Development/Linode ${PROJECT_PASCAL_CASE} DNS Token"
    LINODE_TOKEN=$(get_from_op "required" "${op_key_prefix}/token") && export LINODE_TOKEN || unset LINODE_TOKEN

    op_key_prefix="op://Development/AWS ${PROJECT_PASCAL_CASE} Terraform"
    STATE_ROLE_ARN=$(get_from_op "required" "${op_key_prefix}/state role arn") && export STATE_ROLE_ARN || unset STATE_ROLE_ARN
    DEPLOYMENT_ACCOUNT_ID=$(get_from_op "required" "${op_key_prefix}/deployment account id") && export DEPLOYMENT_ACCOUNT_ID || unset DEPLOYMENT_ACCOUNT_ID
    if [[ -z "${OWNER}" ]]; then
      OWNER=$(get_from_op "required" "${op_key_prefix}/owner") && export OWNER || unset OWNER
    fi

    op_key_prefix="op://Development/SSH Personal Private Key"
    DEPLOYER_PUBLIC_KEY=$(get_from_op "required" "${op_key_prefix}/public key") && export DEPLOYER_PUBLIC_KEY || unset DEPLOYER_PUBLIC_KEY

    export TF_VAR_deployment_account_id="${DEPLOYMENT_ACCOUNT_ID}"
    export TF_VAR_project="${PROJECT}"
    export TF_VAR_domain="${DOMAIN}"
    export TF_VAR_owner="${OWNER}"
    export TF_VAR_deployer_public_key="${DEPLOYER_PUBLIC_KEY}"

  fi
} >&2