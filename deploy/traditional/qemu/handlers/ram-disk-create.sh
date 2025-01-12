
set -e
# echo "$(date) - creating ram disk: ${name}, ${size_512b}, ${image_path}" >> output.actions
state=$(cat)
# echo "stdin: ${state}" >> output.actions

[[ -z "${name}" ]] && echo "name variable not set." && exit 11
[[ -z "${size_512b}" ]] && echo "size_512b variable not set." && exit 12
[[ -z "${image_path}" ]] && echo "image_path variable not set." && exit 13

if ! device=$(hdiutil attach -nomount ram://${size_512b}); then
  echo "Failed to create ram disk."
  exit 1
fi

device=$(printf "${device}" | sed -r 's/(\/dev\/disk[0-9]{1,2}).*/\1/g')
if ! [[ ${device} =~ ^/dev/disk[0-9]+$ ]]; then
  echo "Device [${device}] does not match the expected pattern [^/dev/disk[0-9]+$]."
  exit 2
fi

if ! dd if="${image_path}" of="${device}" bs=64M; then
  hdiutil detach "${device}"
  echo "Failed to write image to ram disk."
  exit 3
fi

echo "{\"device\": \"${device}\", \"name\": \"${name}\", \"size\": \"${size_512b}\", \"image_path\": \"${image_path}\"}"
exit 0
