#!/usr/bin/env bash

snake_to_pascal_case() {
  if [[ -z "${1}" ]]; then
    echo "snake_to_pascal_case (${1}): argument cannot be empty." > /dev/stderr
    return 1
  elif echo "${1}" | grep -q '[^a-z0-9_]'; then
    echo "snake_to_pascal_case (${1}): argument must be in snake case '[a-z0-9_]*'." > /dev/stderr
    return 1
  else
    echo "${1}" | awk -F'_' '{for (i=1; i<=NF; i++) $i=toupper(substr($i,1,1)) substr($i,2)}1' OFS=''
    return 0
  fi
}

pre_flight_check() {
  if [[ "${BASH_SOURCE[1]}" == "${0}" ]]; then
    echo "This script must be sourced, not executed."
    return 1
  elif ! command -v op > /dev/null 2>&1; then
    echo "1Password CLI is not installed."
    return 1
  elif [[ -z "${PROJECT}" ]]; then
    echo "PROJECT is not set."
    return 1
  elif [[ -z "${PROJECT_PASCAL_CASE}" ]]; then
    echo "PROJECT_PASCAL_CASE is not set."
    return 1
  elif [[ -z "${DOMAIN}" ]]; then
    echo "DOMAIN is not set"
    return 1
  else
    return 0
  fi
}

get_from_op() {
  if ! command -v op > /dev/null 2>&1; then
    echo "1Password CLI is not installed." > /dev/stderr
    return 1
  fi
  local mode="${1}"
  local key="${2}"
  local value
  value=$(op read "${key}" 2> /dev/null)
  if [[ "${mode}" == "required" && -z "${value}" ]]; then
    echo "Please fill in 1Password item: ${key}" > /dev/stderr
    return 1
  elif [[ "${mode}" == "optional" && -z "${value}" ]]; then
    return 1
  else
    echo "${value}"
    return 0
  fi
}
