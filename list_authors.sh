#!/bin/bash

cd ..
for folder in ./*; do
    if [ -d "$folder" ]; then
        cd $folder
        git shortlog -nes --all --since=2016-08-01
        cd ..
    fi
done
