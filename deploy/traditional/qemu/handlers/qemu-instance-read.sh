
set -e
# echo "$(date) - reading qemu instance:  ${name}, ${ncpus}, ${memory}, ${uefi_device}, ${boot_device}, ${host_forward}" >> output.actions
state=$(cat)
# echo "stdin: ${state}" >> output.actions

pid="$(echo "${state}" | jq -r '.pid')"
console="$(echo "${state}" | jq -r '.console')"
monitor="$(echo "${state}" | jq -r '.monitor')"

if ! [[ -S "${console}" ]]; then
  echo "Console [${console}] does not exist."
  exit 1
fi

if ! [[ -S "${monitor}" ]]; then
  echo "Monitor [${monitor}] does not exist."
  exit 2
fi

if ! ( ps -p "${pid}" | grep -q "qemu-system-aarch64" ); then
  echo "QEMU instance not found in the expected PID."
  exit 3
fi

set +e
status=$(echo "info status" | socat - UNIX-CONNECT:"${monitor}" | grep -i "VM status:" | tr -d '\r' | cut -b12-)
set -e

echo "{\"name\": \"${name}\", \"console\": \"${console}\", \"monitor\": \"${monitor}\", \"status\": \"${status}\", \"pid\": \"${pid}\"}"

exit 0
