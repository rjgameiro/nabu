#!/usr/bin/env bash

export PROJECT="nabu"
export DOMAIN="bungeebug.com"

export AWS_REGION="eu-west-1"
export AZURE_LOCATION="swedencentral"
export DO_REGION="ams3"

export PROJECT_PASCAL_CASE="$(snake_to_pascal_case "${PROJECT}")"

if [[ -f "${HOME}/.config/op/plugins.sh" ]]; then
  source "${HOME}/.config/op/plugins.sh"
  export COMMAND_PREFIX="op plugin run --"
fi
