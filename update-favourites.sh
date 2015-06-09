#!/bin/bash

# Configure shell
set -euo pipefail
shopt -s nullglob

# Output directory base
declare out_base_dir="collection"
# Name of file listing favourites
declare list="FAVOURITES"
# Image format to render to
declare format="jpg"
# Output directory for full-size
declare fullsize_dir="${out_base_dir}/fullsize"
# Output directory for web versions
declare web_dir="${out_base_dir}/web"
# Max number of parallel operations to run (note: operations may be multithreaded)
declare -i concurrency=2
# Path to watermarking+downsizing script
declare watermark_script="./watermark.sh"
# Path to this script
declare self="$0"

cd "$(dirname "${self}")"

# Read FAVOURITES file and symlink referred files into OUTDIR folder
function update {
	mkdir -p -- "${out_base_dir}"

	local -i errs=0

	while read item; do
		if ! [ -e "${item}" ]; then
			errs=errs+1
			printf -- 'Cannot find file "%s"\n' "${item}"
		fi
	done < "${list}"

	if  (( errs )); then
		printf -- 'No imporing done, %d errors occured\n' "${errs}"
		return ${errs}
	fi

	errs=0

	while read item; do
		local album="${item%% *}"
		local file="${item##*/}"
		local target="${out_base_dir}/${album}-${file}"
		if ! [ -e "${target}" ] && ! ln -sr "${item}" "${target}"; then
			errs=errs+1
			printf -- 'Failed to link "%s" to "%s" "%s"\n' "${item}" "${target}"
		fi
	done < "${list}"

	if (( errs )); then
		printf -- '%d errors occured while importing\n' "${errs}"
		return ${errs}
	fi
}

# Is target missing or older than source?
function up_to_date {
	local item=="$1" target="$2"
	test -e "${target}" && ! test "${target}" -ot "${item}"
}

# Get name of fullsize render target (from source filename)
function get_fullsize_target {
	echo "${fullsize_dir}/$(basename "${1%.*}").${format}"
}

# Get name of web render target (from fullsize target)
function get_web_target {
	echo "${web_dir}/$(basename "${1}")"
}

# Batch render
function batch_parallel {
	local func="$1" mapper="$2"
	shift 2
	if ! (( $# )); then
		return
	fi
	local -a files=( "$@" )
	printf -- "%s\0" "${files[@]}" | \
		xargs -0 -I{} -P${concurrency} \
			nice "${self}" --batch-callback "${func}" "${mapper}" {}
}

# Batch render callback
function batch_callback {
	local func="$1" mapper="$2" item="$3"
	local target="$($mapper "${item}")"
	if ! up_to_date "${item}" "${target}"; then
		${func} "${item}" "${target}"
	fi
}

# Render Nikon raw NEF files
function render_raw {
	rawtherapee \
		-s -p <(printf -- "%s\n" '[Resize]' 'Enabled=false') \
		-j100 \
		-o "$2" -Y -c "$(readlink -f "$1")"
}

# Render JPEG files
function render_jpg {
	cp "$1" "$2"
}

# Render PNG files
function render_png {
	magick "$1" -quality 100 "$2"
}

# Render TIFF files
function render_tif {
	magick "$1" -quality 100 "$2"
}

# Resize and watermark one image
function resize_one {
	"${watermark_script}" "${item}" to "${target}"
}

# Render all
function render {
	mkdir -p -- "${fullsize_dir}"
	batch_parallel 'render_raw' 'get_fullsize_target' "${out_base_dir}"/*.{NEF,nef}
	batch_parallel 'render_jpg' 'get_fullsize_target' "${out_base_dir}"/*.{JPEG,JPG,jpeg,jpg}
	batch_parallel 'render_png' 'get_fullsize_target' "${out_base_dir}"/*.{PNG,png}
	batch_parallel 'render_tif' 'get_fullsize_target' "${out_base_dir}"/*.{TIFF,TIF,tiff,tif}
}

# Resize and watermark for web
function resize {
	mkdir -p -- "${web_dir}"
	batch_parallel 'resize_one' 'get_web_target' "${fullsize_dir}"/*."${format}"
}

# Entry point
function main {
	update
	render
	resize
}

# Intercept callbacks from parallel batch mapper
if [ "${1:-}" == '--batch-callback' ]; then
	shift
	if [ "${TEST:-}" ]; then
		echo batch_callback "$@"
	else
		batch_callback "$@"
	fi
else
	main
fi