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

    if [[ -z "${OWNER}" ]]; then
      op_key_prefix="op://Development/QEMU ${PROJECT_PASCAL_CASE} Terraform"
      OWNER=$(get_from_op "required" "${op_key_prefix}/owner") && export OWNER || unset OWNER
    fi

    export TF_VAR_project="${PROJECT}"
    export TF_VAR_domain="${DOMAIN}"
    export TF_VAR_owner="${OWNER}"
    export TF_VAR_uefi_image_path="${HOME}/Temporary/QEMU/uefi-drive-debian-12.raw"
    export TF_VAR_boot_image_path="${HOME}/Temporary/QEMU/boot-drive-debian-12.raw"
    export TF_VAR_environment_names='["develop"]'

  fi
} >&2