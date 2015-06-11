#!/bin/bash

set -euo pipefail
shopt -s nullglob

source 'X-shared.sh'

python 4-calc-layout.py
