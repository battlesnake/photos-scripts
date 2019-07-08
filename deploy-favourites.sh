#!/bin/bash

set -e

shopt -s nullglob

cd "$(dirname "$0")"

rsync -sr --delete 000\ Collection/web/ deadpool:empire/hackology/sites/photos/
#tar -c *.jpg *.JPG index.html | ssh deadpool './empire/photos/receive-update.sh'
