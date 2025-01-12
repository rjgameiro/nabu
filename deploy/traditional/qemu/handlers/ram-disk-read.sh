
file_sha512() {
   # Calculate the SHA512 hash
   image_sha512=$(dd if="$1" bs=$2 count=1 2>/dev/null | shasum -b -a 512 | awk '{print $1}')

   # Capture exit statuses of the pipeline commands
   s1=${PIPESTATUS[0]} # Status of 'dd'
   s2=${PIPESTATUS[1]} # Status of 'shasum'
   s3=${PIPESTATUS[2]} # Status of 'awk'

   # Check for errors
   if [[ $s1 -ne 0 ]]; then
     echo "Failed to read image."
     exit 11
   elif [[ $s2 -ne 0 ]]; then
     echo "Failed to calculate sha512 of image."
     exit 12
   elif [[ $s3 -ne 0 ]]; then
     echo "Failed to parse sha512."
     exit 13
   fi

   # Return the calculated hash
   echo "$image_sha512"
 }

set -e
# echo "$(date) - reading ram disk: ${name}, ${size_512b}, ${image_path}" >> output.actions
state=$(cat)
# echo "stdin: ${state}" >> output.actions

device=$(echo "${state}" | jq -r '.device')
if diskutil info "${device}" | grep -q " ${size_512b} "; then

  image_sha=$(file_sha512 "${image_path}" 8192)
  disk_sha=$(file_sha512 "${device}" 8192)

  if [[ "${image_sha}" == "${disk_sha}" ]]; then
    echo "{\"device\": \"${device}\", \"name\": \"${name}\", \"size\": \"${size_512b}\", \"image_path\": \"${image_path}\"}"
    exit 0
  else
    echo "{\"device\": \"${device}\", \"name\": \"${name}\", \"size\": \"${size_512b}\", \"image_path\": null}"
    exit 1
  fi

else
  echo "{\"device\": null, \"name\": null, \"size\": null, \"image_path\": null}"
  exit 2
fi
