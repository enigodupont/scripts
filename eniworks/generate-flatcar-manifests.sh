#!/bin/bash


export FLATCAR_HOSTNAME="$1"
export FLATCAR_IP="$2"
DEBUG="$DEBUG"

debug() {
  if ! [ -z "$DEBUG" ]
  then
    echo "$1"
  fi
}

if [ -z "$FLATCAR_HOSTNAME" ] | [ -z "$FLATCAR_IP" ]
then
 echo "Not enough arguments provided, exiting..."
 echo "$0 FLATCAR_HOSTNAME FLATCAR_IP"
 exit 1
fi

flatcar_yaml=$(cat flatcar-template.yaml | envsubst)
debug "$flatcar_yaml"
flatcar_json=$(echo "$flatcar_yaml" | docker run --rm -i quay.io/coreos/ct:latest-dev)
debug "$flatcar_json"
flatcar_encoded=$(echo "$flatcar_json" | base64 -w0)

echo "---------- Flatcar config encoding ----------"
echo "$flatcar_encoded"
echo "---------- Flatcar config encoding type ----------"
echo "base64"

