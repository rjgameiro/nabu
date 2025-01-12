
set -e

# echo "$(date) - creating qemu instance:  ${name}, ${ncpus}, ${memory}, ${uefi_device}, ${boot_device}, ${host_forward}" >> output.actions
state=$(cat)
# echo "stdin: ${state}" >> output.actions

[[ -z "${name}" ]] && echo "name variable not set." && exit 11
[[ -z "${uefi_device}" ]] && echo "uefi_device variable not set." && exit 12
[[ -z "${boot_device}" ]] && echo "boot_device variable not set." && exit 13
[[ -z "${ncpus}" ]] && echo "cpu variable not set." && exit 14
[[ -z "${memory}" ]] && echo "memory variable not set." && exit 15

if ! [[ -e "${uefi_device}" ]]; then
  echo "UEFI device [${uefi_device}] does not exist."
  exit 2
fi

if ! [[ -e "${boot_device}" ]]; then
  echo "Boot device [${boot_device}] does not exist."
  exit 3
fi

host_forward_argument=""
for port_set in $(echo "${host_forward}" | tr -d ' ' | tr ',' ' '); do
   host_forward_argument="${host_forward_argument},hostfwd=${port_set}"
done

console="/tmp/${name}-console.sock"
monitor="/tmp/${name}-monitor.sock"

nohup qemu-system-aarch64 \
  -accel hvf \
  -m ${memory} \
  -M virt,highmem=off \
  -smp cpus=${ncpus} \
  -cpu cortex-a57 \
  -rtc base=localtime,clock=host \
  -device virtio-serial \
  -device virtserialport,chardev=qga0,name=org.qemu.guest_agent.0 \
  -chardev socket,id=qga0,path=/tmp/qga.sock,server=on,wait=off \
  -drive file=/opt/homebrew/share/qemu/edk2-aarch64-code.fd,if=pflash,format=raw,readonly=on \
  -drive file=${uefi_device},if=pflash,format=raw \
  -drive file=${boot_device},if=none,format=raw,id=hd0 \
  -device virtio-blk-device,drive=hd0,serial="dummyserial" \
  -rtc base=localtime,clock=host \
  -netdev user,id=net0${host_forward_argument} \
  -device virtio-net-pci,netdev=net0 \
  -serial unix:${console},server=on,wait=off \
  -monitor unix:${monitor},server=on,wait=off \
  -nographic \
> /dev/null 2>&1 &
pid=$!
[[ $? -ne 0 ]] && echo "Failed to launch qemu." && exit 4

set +e
count=30
status="unknown"
while [[ "${status}" != "running" && "${count}" -gt 0 ]]; do
  sleep 2
  status=$(echo "info status" | socat - UNIX-CONNECT:"${monitor}" | grep -i "VM status:" | tr -d '\r' | cut -b12-)
  count=$((count-1))
done

if [[ "${status}" != "running" ]]; then
  echo "Instance failed to start within the expected time."
  kill -9 "${pid}"
  exit 5
fi
set -e

echo "{\"name\": \"${name}\", \"console\": \"${console}\", \"monitor\": \"${monitor}\", \"status\": \"${status}\", \"pid\": \"${pid}\"}"
exit 0
