#!/usr/bin/env bash

nextip(){
    IP=$1
    IP_HEX=$(printf '%.2X%.2X%.2X%.2X\n' `echo $IP | sed -e 's/\./ /g'`)
    NEXT_IP_HEX=$(printf %.8X `echo $(( 0x$IP_HEX + 1 ))`)
    NEXT_IP=$(printf '%d.%d.%d.%d\n' `echo $NEXT_IP_HEX | sed -r 's/(..)/0x\1 /g'`)
    echo "$NEXT_IP"
}

add_router_nics() {
    gcloud compute routers add-interface $1 --interface-name=ra-1-0 --ip-address=$2 --subnetwork=$3 --region=$4 --project=$5
    BACKUP_IP=$(nextip $2)
    gcloud compute routers add-interface $1 --interface-name=ra-1-1 --ip-address=$BACKUP_IP --subnetwork=$3 --redundant-interface=ra-1-0 --region=$4 --project=$5
}

add-bgp-peers() {
  gcloud compute routers add-bgp-peer $1 --peer-name=ra-1-0-peer0 --interface=ra-1-0 --peer-ip-address=$2 --peer-asn=$3 --instance=$4 --instance-zone=$5-a --region=$5 --bfd-session-initialization-mode=passive --project=$6
  gcloud compute routers add-bgp-peer $1 --peer-name=ra-1-1-peer0 --interface=ra-1-1 --peer-ip-address=$2 --peer-asn=$3 --instance=$4 --instance-zone=$5-a --region=$5 --bfd-session-initialization-mode=passive --project=$6
}

remove-bgp-peers() {
  gcloud compute routers remove-bgp-peer $1 --peer-name=ra-1-1-peer0 --region=$2 --project=$3
  gcloud compute routers remove-bgp-peer $1 --peer-name=ra-1-0-peer0 --region=$2 --project=$3
}

test() {
  echo "$@"
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