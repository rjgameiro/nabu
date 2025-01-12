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

    op_key_prefix="op://Development/Linode ${PROJECT_PASCAL_CASE} DNS Token"
    LINODE_TOKEN=$(get_from_op "required" "${op_key_prefix}/token") && export LINODE_TOKEN || unset LINODE_TOKEN

    op_key_prefix="op://Development/Azure ${PROJECT} Terraform"
    ARM_SUBSCRIPTION_ID=$(get_from_op "required" "${op_key_prefix}/subscriptionId") && export ARM_SUBSCRIPTION_ID || unset ARM_SUBSCRIPTION_ID
    ARM_TENANT_ID=$(get_from_op "required" "${op_key_prefix}/tenantId") && export ARM_TENANT_ID || unset ARM_TENANT_ID
    ARM_CLIENT_ID=$(get_from_op "required" "${op_key_prefix}/appId") && export ARM_CLIENT_ID || unset ARM_CLIENT_ID
    ARM_CLIENT_SECRET=$(get_from_op "required" "${op_key_prefix}/password") && export ARM_CLIENT_SECRET || unset ARM_CLIENT_SECRET
    if [[ -z "${OWNER}" ]]; then
      OWNER=$(get_from_op "required" "${op_key_prefix}/owner") && export OWNER || unset OWNER
    fi

    op_key_prefix="op://Development/SSH Personal Private Key"
    DEPLOYER_PUBLIC_KEY=$(get_from_op "required" "${op_key_prefix}/public key") && export DEPLOYER_PUBLIC_KEY || unset DEPLOYER_PUBLIC_KEY

    export TF_VAR_project="${PROJECT}"
    export TF_VAR_domain="${DOMAIN}"
    export TF_VAR_owner="${OWNER}"
    export TF_VAR_deployer_public_key="${DEPLOYER_PUBLIC_KEY}"
    export TF_VAR_environment_names='["stage"]'

  fi
} >&2