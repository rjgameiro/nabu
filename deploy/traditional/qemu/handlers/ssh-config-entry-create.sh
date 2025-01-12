
set -e

# echo "$(date) - creating host entry: ${ssh_fqdn}, ${ssh_port}" >> output.actions
#state=$(cat)
# echo "stdin: ${state}" >> output.actions

[[ -z "${ssh_fqdn}" ]] && echo "ssh_fqdn variable not set." && exit 12
[[ -z "${ssh_port}" ]] && echo "ssh_port variable not set." && exit 13

set +e
{
  ansible-playbook \
    --extra-vars="state=\"present\"" \
    --extra-vars="ssh_fqdn=\"${ssh_fqdn}\"" \
    --extra-vars="ssh_port=\"${ssh_port}\"" \
    handlers/ssh-config-entry.yml
} > /dev/null 2>&1
[[ $? -ne 0 ]] && echo "Failed to create ssh config entry." && exit 1
set -e

echo "{\"ssh_fqdn\": \"${ssh_fqdn}\", \"ssh_port\": \"${ssh_port}\"}"
exit 0