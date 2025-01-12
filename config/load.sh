#!/usr/bin/env bash

source functions.sh
[ -f "variables.sh" ] && source variables.sh
[ -f "sensitive.sh" ] && source sensitive.sh
[ -f "rust_apis.yml" ] && export RUST_APIS="rust_apis.yml"

CONFIG_LOADED="YES"