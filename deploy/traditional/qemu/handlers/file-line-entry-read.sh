
set -e

# echo "$(date) - reading host entry: ${prefix}, ${entry}, ${file}, ${become_root}" >> output.actions
state=$(cat)
# echo "stdin: ${state}" >> output.actions

[[ -z "${prefix}" ]] && echo "prefix variable not set." && exit 11
[[ -z "${entry}" ]] && echo "entry variable not set." && exit 12
[[ -z "${file}" ]] && echo "file variable not set." && exit 13
[[ -z "${become_root}" ]] && echo "become_root variable not set." && exit 14

set +e
{
  ansible-playbook \
    --extra-vars="prefix=\"${prefix}\"" \
    --extra-vars="entry=\"${entry}\"" \
    --extra-vars="file=\"${file}\"" \
    --extra-vars="become_root=\"${become_root}\"" \
    handlers/file-line-entry-create.yml --check | grep "changed=0"
} > /dev/null 2>&1
[[ $? -ne 0 ]] && echo "Failed to read file entry." && exit 1
set -e

echo "{\"prefix\": \"${prefix}\", \"entry\": \"${entry}\"}"
exit 0