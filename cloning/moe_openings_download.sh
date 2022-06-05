#!/bin/bash

video_repo='https://openings.moe/video/'

openings=` curl -Lks "https://openings.moe/api/list.php?eggs&shuffle" | jq .`
len=`echo $openings | jq '. | length'`

download_path='downloaded_op_ed'

mkdir -p ./$download_path

for ((i = 0 ; i <= $len ; i++))
do
  filename=`echo $openings | jq .[$i].file |  tr -d '"'`
  echo "FileName - $filename.mp4"
  filepath="$video_repo$filename.mp4"
  echo "Downloading - $filepath"
  wget "$filepath" -O "$download_path/$filename.mp4"
done
