
set -e
# echo "$(date) - deleting qemu instance:  ${name}, ${ncpus}, ${memory}, ${uefi_device}, ${boot_device}, ${host_forward}" >> output.actions
state=$(cat)
# echo "stdin: ${state}" >> output.actions

pid="$(echo "${state}" | jq -r '.pid')"
monitor="$(echo "${state}" | jq -r '.monitor')"

set +e
status=$(echo "info status" | socat - UNIX-CONNECT:"${monitor}" | grep -i "VM status:" | tr -d '\r' | cut -b12-)
if [[ "${status}" == "running" || "${status}" == "paused"  ]]; then

  echo "system_powerdown" | socat - UNIX-CONNECT:"${monitor}" > /dev/null 2>&1
  count=30
  while [[ "${status}" == "running" && "${count}" -gt 0 ]]; do
    sleep 2
    status=$(echo "info status" | socat - UNIX-CONNECT:"${monitor}" | grep -i "VM status:" | tr -d '\r' | cut -b12-)
    count=$((count-1))
  done

  if [[ "${status}" == "running" ]]; then
    echo "quit" | socat - UNIX-CONNECT:"${monitor}" > /dev/null 2>&1
    sleep 1
    kill "${pid}"
  fi

fi
set -e

echo "{\"name\": null, \"console\": null, \"monitor\": null, \"status\": null, \"pid\": null}"
exit 0
