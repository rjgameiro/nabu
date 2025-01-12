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

    op_key_prefix="op://Development/DO ${PROJECT_PASCAL_CASE} Terraform"
    DIGITALOCEAN_TOKEN=$(get_from_op "required" "${op_key_prefix}/token") && export DIGITALOCEAN_TOKEN || unset DIGITALOCEAN_TOKEN
    if [[ -z "${OWNER}" ]]; then
      OWNER=$(get_from_op "required" "${op_key_prefix}/owner") && export OWNER || unset OWNER
    fi

  fi
} >&2
