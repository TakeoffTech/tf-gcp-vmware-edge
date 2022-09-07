#!/usr/bin/env bash
# Copyright 2019 Takeoff Technologies Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

nextip(){
    IP=$1
    # shellcheck disable=SC2046,SC2183,SC2001
    IP_HEX=$(printf '%.2X%.2X%.2X%.2X\n' $(echo "$IP" | sed -e 's/\./ /g'))
    # shellcheck disable=SC2046,SC2116
    NEXT_IP_HEX=$(printf %.8X $(echo $(( 0x$IP_HEX + 1 ))))
    # shellcheck disable=SC2046,SC2183
    NEXT_IP=$(printf '%d.%d.%d.%d\n' $(echo "$NEXT_IP_HEX" | sed -r 's/(..)/0x\1 /g'))
    echo "$NEXT_IP"
}

add_router_nics() {
    gcloud compute routers add-interface "$1" --interface-name=ra-1-0 --ip-address="$2" --subnetwork="$3" --region="$4" --project="$5"
    BACKUP_IP=$(nextip "$2")
    gcloud compute routers add-interface "$1" --interface-name=ra-1-1 --redundant-interface=ra-1-0 --ip-address="$BACKUP_IP" --subnetwork="$3" --region="$4" --project="$5"
}

add-bgp-peers() {
  gcloud compute routers add-bgp-peer "$1" --peer-name=ra-1-0-peer0 --interface=ra-1-0 --peer-ip-address="$2" --peer-asn="$3" --instance="$4" --instance-zone="$5"-a --region="$5" --bfd-session-initialization-mode=passive --project="$6" --advertisement-mode=default
  gcloud compute routers add-bgp-peer "$1" --peer-name=ra-1-1-peer0 --interface=ra-1-1 --peer-ip-address="$2" --peer-asn="$3" --instance="$4" --instance-zone="$5"-a --region="$5" --bfd-session-initialization-mode=passive --project="$6" --advertisement-mode=default
}

remove-bgp-peers() {
  gcloud compute routers remove-bgp-peer "$1" --peer-name=ra-1-1-peer0 --region="$2" --project="$3"
  gcloud compute routers remove-bgp-peer "$1" --peer-name=ra-1-0-peer0 --region="$2" --project="$3"
}

if declare -f "$1" > /dev/null
then
  # call arguments verbatim
  "$@"
else
  # Show a helpful error
  echo "'$1' is not a known function name" >&2
  exit 1
fi
