#!/bin/bash

set -euo pipefail
shopt -s nullglob

source 'X-shared.sh'

function index_size {
	local out_size="$1"
	for img in "${out_size}"/*.jpg; do
		IFS=$'\t' local -a dim=( $(magick "${img}" -format $'%w\t%h' info:-) )
		IFS=$'\t' local -a meta=( $(exif_cmd "${exif[@]}" "${img}" | perl -pe 's/\ //g') )
		if (( ${#meta[@]} != 4 || ${#dim[@]} != 2 )); then
			errout "Failed to analyse '%s'\nData: %s\n" "${img}" "dim = [ ${dim[*]} ]  exif = [ ${meta[*]} ]"
			return 1
		fi
		printf -- "%s\t%d\t%d\t%s\t%s\t%s\t%s\t%s\t%s\n" "${out_size}" "${dim[@]}" "${meta[@]}" "${img}"
		errout 'x'
	done
	errout "\n"
}

for size in "${sizes[@]}"; do
	index_size "${size}"
done > "${index}"
