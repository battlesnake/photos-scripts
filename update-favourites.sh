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
# Max number of parallel render operations to run (note: operations may be multithreaded)
# Would set to 4 on my i7 for 100% CPU usage, but anything above 1 uses too much RAM
declare -i render_concurrency=1
# Number of parallel watermark operations to run
declare -i watermark_concurrency=4
# Path to watermarking+downsizing script
declare watermark_script="./watermark.sh"
# Options for watermark script
declare -a watermark_opts=( --output-size 1280x1280\> --output-quality 50 --silent )
# Path to this script
declare self="$(realpath "$0")"
declare self_path="$(dirname "${self}")"
# Name of index HTML file
declare index_html="index.html"

cd "${self_path}"

# Read FAVOURITES file and symlink referred files into OUTDIR folder
function update {
	mkdir -p -- "${out_base_dir}"

	local -i errs=0

	while read item; do
		if printf -- "%s" "${item}" | grep -qE '^#'; then
			continue
		fi
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
		if printf -- "%s" "${item}" | grep -qE '^#'; then
			continue
		fi
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
	local func="$1" concurrency="$2" mapper="$3"
	shift 3
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
		if ! ${func} "${item}" "${target}"; then
			printf -- "Failed to process %s => %s\n" "${item}" "${target}"
			rm -f -- "${target}"
			return 1
		fi
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
	"${watermark_script}" "${watermark_opts[@]}" "${item}" to "${target}"
}

# Render all
function render {
	mkdir -p -- "${fullsize_dir}"
	batch_parallel 'render_raw' "${render_concurrency}" 'get_fullsize_target' "${out_base_dir}"/*.{NEF,nef}
	batch_parallel 'render_jpg' "${render_concurrency}" 'get_fullsize_target' "${out_base_dir}"/*.{JPEG,JPG,jpeg,jpg}
	batch_parallel 'render_png' "${render_concurrency}" 'get_fullsize_target' "${out_base_dir}"/*.{PNG,png}
	batch_parallel 'render_tif' "${render_concurrency}" 'get_fullsize_target' "${out_base_dir}"/*.{TIFF,TIF,tiff,tif}
}

# Resize and watermark for web
function resize {
	mkdir -p -- "${web_dir}"
	batch_parallel 'resize_one' "${watermark_concurrency}" 'get_web_target' "${fullsize_dir}"/*."${format}"
}

# Generate index HTML file
function make_index { (
	echo "Generating index"
	cd "${web_dir}"
	printf -- '%s\n' \
		'<!doctype html>' '<html>' '<head>' \
		'<meta charset="utf-8">' '<title>Mark'\''s photos</title>' \
		'<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">' \
		'<style>' \
		'* { box-sizing: border-box; }' \
		'html { margin: 0; padding: 0; font-size: 62.5%; }' \
		'a { text-decoration: none; color: inherit; }' \
		'body { font-family: sans-serif; background: #222; padding: 20px; color: #eee; font-size: 1.4rem; }' \
		'p { margin: 10px 0; }' \
		'h1 { font-size: 2.4rem; margin: 16px 0; }' \
		'h2 { font-size: 1.6rem; text-align: center; margin: 30px 0 20px; padding-top: 30px; border-top: 1px solid #888; }' \
		'.hide { display: none; }' \
		'.gallery { display: flex; flex-flow: row wrap; list-style-type: none; margin: 0 -10px; padding: 0; justify-content: center; align-items: center; } ' \
		'.gallery-item { margin: 10px; padding: 10px; border-radius: 10px; background: #444; transition: transform 200ms ease-in; transform-origin: center center; }' \
		'.gallery-item:hover { transform: scale(1.1); }' \
		'.gallery-item:active, .gallery-item:focus { transform: rotate(5deg); }' \
		'.gallery-item img { border: 0; height: 220px; }' \
		'</style>' \
		'</head>' '<body>' \
		'<header>' \
		'<h1>Mark'\''s travel photos</h1>' \
		'<p>All content &copy; Mark K Cowan</p>' \
		'<p>Some photos may belong to the previous or next album rather than the one they appear in, I occasionally forget to create new folders on my camera when arriving in a new place...</p>' \
		'</header>' \
		'<main>' \
		'<ul class="hide">' \
		> "${index_html}"
set -x

	for name in *.jpg; do
		local src="$(ls ../"${name%.*}".* | head -n1)"
		if [ -z "${src}" ] || ! [ -e "${src}" ]; then
			printf >&2 "Error: failed to find source for \"%s\"\n" "${src}"
			continue
		fi
		src="$(realpath --relative-to="${self_path}" "$(readlink -f "${src}")")"
		local group="${src%%/*}"
		local group_name="$(echo "${group}" | perl -pe 's/^\d{3}\s+//g')"
		local group_id="$(echo "${group}" | grep -Po '^\d{3}')"
		printf -- "%s\t%s\t%s\t%s\n" "${name}" "${group}" "${group_name}" "${group_id}"
	done | \
		sort -s -t$'\t' -k3,3 -d | \
		sort -s -t$'\t' -k4,4 -n | \
	(
		local last_group=''
		while IFS=$'\t' read name group group_name group_id; do
			if [ "${group}" != "${last_group}" ]; then
				last_group="${group}"
				printf -- '\t%s\n' \
					'</ul>' \
					"<h2>${group_name}</h2>" \
					'<ul class="gallery">' \
					>> "${index_html}"
			fi
			printf -- '\t%s\n' \
				'<li class="gallery-item">' \
				"<a href=\"${name}\">" \
				"<img src=\"${name}\">" \
				'</a>' \
				'</li>' \
				>> "${index_html}"
		done
	)
	printf -- '%s\n' \
		'</ul>' \
		'</main>' \
		'</body>' \
		'</html>' \
		>> "${index_html}"
) }

# Upload web images and index HTML to server
function upload { (
	echo >&2 "Uploading"
	cd "${web_dir}"
	rsync -avzlr --delete --progress \
		*.${format} "${index_html}" \
		hacksh@app.kuckian.co.uk:/var/www/hackology.co.uk/public_html/photos/
) }

# Entry point
function main {
	update
	render
	resize
	make_index
	upload
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
