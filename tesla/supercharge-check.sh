#!/bin/bash

updates="$(curl -s 'https://supercharge.info/service/supercharge/changes?length=150')"

echo "$updates" | jq -c '.results[] | select(.siteName | contains("TX"))' 
