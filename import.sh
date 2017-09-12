#!/bin/bash

set -euo pipefail

echo >&2 "Synchronizing..."
rsync "$@" -avzlrm --stats --progress ploom@fs.kuckian.co.uk:photos/ /home/mark/Nikon

echo >&2 "Done..."
