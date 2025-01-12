
set -e
# echo "$(date) - deleting ram disk: ${name}, ${size_512b}, ${image_path}" >> output.actions
state=$(cat)
# echo "stdin: ${state}" >> output.actions

device=$(echo "${state}" | jq -r '.device')
if diskutil info "${device}" | grep -q " ${size_512b} "; then
  hdiutil detach "${device}"
  if [[ $? -ne 0 ]]; then
    echo "Failed to delete ram disk."
    exit 1
  fi
else
  echo "Ram disk not found."
  exit 2
fi

echo "{\"device\": null, \"name\": null, \"size\": null, \"image_path\": null}"
exit 0
