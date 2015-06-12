#!/bin/bash

set -euo pipefail

source 'X-shared.sh'

mkdir -p -- "${output_dir}"

export annot_dir output_image page_width page_height preserve_order layout_image

nice python 4-generate-layout.py
