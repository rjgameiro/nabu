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

    op_key_prefix="op://Development/AWS ${PROJECT_PASCAL_CASE} Terraform"
    AWS_PROFILE=$(get_from_op "optional" "${op_key_prefix}/profile") && export AWS_PROFILE || unset AWS_PROFILE
    STATE_AWS_PRINCIPAL=$(get_from_op "required" "${op_key_prefix}/state principal arn") && export STATE_AWS_PRINCIPAL || unset STATE_AWS_PRINCIPAL
    OWNER=$(get_from_op "required" "${op_key_prefix}/owner") && export OWNER || unset OWNER

  fi
} >&2
