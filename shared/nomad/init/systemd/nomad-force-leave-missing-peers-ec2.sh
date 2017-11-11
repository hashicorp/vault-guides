#!/usr/bin/env bash

set -e

# getMyRegion returns the region in which the current instance is running,
# based on the availability zone read from the EC2 metadata service.
#
# Parameters:
#     None.
function getMyRegion() {
  local metadata_base_url="http://169.254.169.254/latest/meta-data"
  local this_instance_az

  this_instance_az=$(curl --silent --location ${metadata_base_url}/placement/availability-zone)

  #shellcheck disable=SC2001
  echo "${this_instance_az}" | sed 's/.$//'
}

# getMyIPAddress returns the private IP address of the current instance,
# from the EC2 metadata service (rather than parsing the output of ifconfig
# or similar utilities).
#
# Parameters:
#     None.
function getMyIPAddress() {
  local metadata_base_url="http://169.254.169.254/latest/meta-data"

  curl --silent --location "${metadata_base_url}/local-ipv4"
}

# getMyASGName returns the name of the autoscaling group of which the current
# instance is running, based on the aws:autoscaling:groupName tag which is
# populated by the autoscaling control system.
#
# Parameters:
#     $1: the name of the region in which the instance is running.
function getMyASGName() {
  local region=$1
  local metadata_base_url="http://169.254.169.254/latest/meta-data"

  local this_instance_id

  this_instance_id=$(curl --silent --location ${metadata_base_url}/instance-id)

  aws ec2 describe-tags \
    --region "${region}" \
    --filters "Name=resource-type,Values=instance" \
    "Name=resource-id,Values=${this_instance_id}" \
    "Name=key,Values=aws:autoscaling:groupName" \
    --query "Tags[0].Value" \
    --output=text
}

# getInstanceAddressesInASG returns a list of private IP addresses for
# instances in a running or pending state which are members of the given
# autoscaling group, sorted in ascending order of launch time (oldest first).
#
# Parameters:
#     $1: the name of the region in which the ASG exists
#     $2: the name of the autoscaling group
function getRunningInstanceAddressesInASG() {
  local region=$1
  local asg_name=$2
  local metadata_base_url="http://169.254.169.254/latest/meta-data"

  local instances_in_asg
  local running_instances

  instances_in_asg=$(aws autoscaling describe-auto-scaling-groups \
    --region "${region}" \
    --auto-scaling-group-names="${asg_name}" \
    --query "AutoScalingGroups[0].Instances[*].{InstanceId:InstanceId}" \
    --output text)

  #shellcheck disable=SC2086
  running_instances=$(aws ec2 describe-instance-status \
    --region "${region}" \
    --instance-ids ${instances_in_asg} \
    --filter "Name=instance-state-name,Values=pending,running" \
    --query "InstanceStatuses[*].InstanceId" \
    --output text)

  #shellcheck disable=SC2086
  aws ec2 describe-instances \
    --region "${region}" \
    --instance-ids ${running_instances} \
    --query "Reservations[*].Instances[*].{LaunchTime:LaunchTime,PrivateIpAddress:PrivateIpAddress}" \
    --output text | sort -s -n -k 1,1 | cut -f 2 -s
}

function findOtherNomadNode() {
  local this_ip=$1

  curl --silent "http://127.0.0.1:4646/v1/agent/members" \
    | jq -M -r '.Members[] | .Addr' \
    | cut -d ':' -f1 \
    | grep -v "${this_ip}" \
    | head -n 1
}

# getNomadRaftPeers returns a list of the IP addresses of the Nomad servers
# according to the /v1/agent/members endpoint. We always query the local Nomad
# agent to find who to talk to.
function getNomadRaftPeers() {
  local to_ask=$1

  curl --silent "http://${to_ask}:4646/v1/agent/members" \
    | jq -M -r '.Members[] | .Addr' \
    | cut -d ':' -f1
}

# forceLeaveRaftPeer force leaves the given node from the Nomad cluster.
#
# Parameters:
#     $1: The address of the node to force leave
function forceLeaveRaftPeer() {
  local node_address_to_leave=$1

  local node_id_to_leave

  node_id_to_leave=$(curl --silent "http://${to_talk_to}:4646/v1/agent/members" \
    | jq -M -r ".Members[] | select(.Addr == \"${node_address_to_leave}\") | .Name")

  if [ ! -z "${node_id_to_leave}" ] ; then
    /usr/bin/nomad server-force-leave ${node_id_to_leave}
  fi
}

# forceLeaveOldServers compares the list of current Nomad raft peers obtained
# via the /v1/agent/members endpoint with the list of instances which
# are running or pending in the autoscaling group, and force leaves any servers
# which are not running or pending. We use the local Nomad Agent for queries
# and to carry out the force-leave operation.
#
# Parameters:
#     None
function forceLeaveOldServers() {
  local this_instance_region
  local this_asg_name
  local this_ip_address
  local to_talk_to

  this_instance_region=$(getMyRegion)
  this_ip_address=$(getMyIPAddress)
  this_asg_name=$(getMyASGName "${this_instance_region}")

  to_talk_to=$(findOtherNomadNode "${this_ip_address}")
  nomad_raft_peers=$(getNomadRaftPeers "${to_talk_to}")
  instances_in_asg=$(getRunningInstanceAddressesInASG "${this_instance_region}" "${this_asg_name}")

echo "here"

  for peer in ${nomad_raft_peers}; do
    if [ -z "$(echo "${instances_in_asg}" | grep "${peer}")" ] ; then
      echo "Force leaving ${peer} from Nomad..."
      forceLeaveRaftPeer "${peer}"
    fi
  done
}

forceLeaveOldServers
