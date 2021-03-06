#!/bin/bash

set -euo pipefail

# May be overridden by command line arguments
declare output_quality="55"
declare output_size="900x"

# Subdirectory to output to (used by watermark_folder)
declare -r batch_out="marked"

# Watermark configuration
declare -r text="hackology.co.uk"
declare -r text_font="$(dirname "$0")/.fonts/Open_Sans-normal-600.ttf"
declare -r text_size="55"
declare -r text_color="#0004"
declare -r bg_color="white"

declare -r wm_file="/tmp/wm.png"
declare -r wm_width="500"
declare -r wm_height="100"
declare -r wm_radius="50"
declare -r wm_offset="+75+0"
declare -r wm_origin="southeast"

declare -ar wm_extra=(
	-strip
	-interlace Plane
	-gaussian-blur 0.8x5
	-unsharp 2x0.5+0.7+0
	-sampling-factor 4:2:0
)

declare -r comment='© Mark K Cowan, mark@battlesnake.co.uk'

# If output size is set via command line, working size will be enlarged if needed
declare working_size="2400x"

declare silent=0

declare magick=

# Get name of imagemagick
if which magick 2>/dev/null >/dev/null; then
	magick=magick
elif which convert 2>/dev/null >/dev/null; then
	magick=convert
else
	echo >&2 "Imagemagick not found"
	exit 1
fi

# Render the watermark
function render_watermark {
	if ! (( silent )); then
		printf -- "Rendering watermark to \"%s\"\n" "${wm_file}" >&2
	fi
	rm -f "${wm_file}"
	nice "$magick" \
		-gravity "center" \
		\( \
			-size "${wm_width}x${wm_height}" xc:none \
			-fill "${bg_color}" \
			-draw "roundrectangle 0,0 ${wm_width},$((wm_height + wm_radius)) ${wm_radius},${wm_radius}" \
		\) \
		\( \
			-size "${wm_width}x${wm_height}" xc:none \
			-fill "black" -stroke "black" \
			-gravity "center" -pointsize "${text_size}" -font "${text_font}" \
			-annotate "+0+0" "${text}" \
		\) \
		-compose "Dst_Out" -composite -alpha "set" \
		\( \
			-size "${wm_width}x${wm_height}" xc:none \
			-fill "${text_color}" -stroke "${text_color}" \
			-gravity "center" -pointsize "${text_size}" -font "${text_font}" \
			-annotate "+0+0" "${text}" \
		\) \
		-compose "Dst_Over" -composite \
		-set comment "${comment}" \
		"${wm_file}"
}

# Generate watermark if needed
function watermark_needed {
	if ! [ -e "${wm_file}" ]; then
		render_watermark
	fi
}

# Watermark a file $1, output to file $2
function watermark_file {
	watermark_needed
	local in="$1" out="$2"
	if ! (( silent )); then
		printf -- "\e[37m%s\e[37m => \e[32m%s\e[37m\n" "${in##*/}" "${out}" >&2
	fi
	nice "$magick" \
		\( \
			\( "${in}" -resize "${working_size}" "${wm_extra[@]}" \) \
			\( "${wm_file}" -geometry "${wm_offset}" -gravity "${wm_origin}" \) \
			-compose "atop" -composite \
		\) \
		-resize "${output_size}" \
		-quality "${output_quality}" \
		"${out}"
}

# Watermark all the jpegs in folder $1, output to a subfolder $batch_out
function watermark_folder {
	watermark_needed
	local dir="$1"
	local in="${dir}"
	local out="${dir}/${batch_out}"
	if ! [ -d "${out}" ]; then
		mkdir "${out}"
	fi
	local src dest
	if ! (( silent )); then
		printf -- "\e[33m%s\e[37m\n" "${dir}" >&2
	fi
	for src in "${in}"/*.jpg; do
		dest="${out}/${src#${in}}"
		watermark_file "${src}" "${dest}"
	done
}

# Parse a size in the form \d*x\d*
function parse_size {
	declare size="$1"
	printf -- "%s\n" "$(echo "${size}" | cut -dx -f1 | perl -pe 's/[^\d]+$//g')" "$(echo "${size}" | cut -dx -f2 | perl -pe 's/[^\d]+$//g')"
}

# Ensure that the working size is at least as big as the output size
function check_working_size {
	readarray -t out < <(parse_size "${output_size}")
	readarray -t work < <(parse_size "${working_size}")
	for (( i=0; i<2; i++ )); do
		if [ "${out[$i]}" ] && [ "${work[$i]}" ] && (( ${out[$i]} > ${work[$i]} )); then
			work[$i]="${out[$i]}"
		fi
	done
	working_size="${work[0]}x${work[1]}"
}

declare param

while (( $# )); do
	param="$1"
	shift
	if (( $# >= 2 )) && [ "$1" == "to" ]; then
		if ! [ -f "${param}" ]; then
			printf -- "Cannot find input file \"%s\"\n" "${param}"
			exit 1
		fi
		shift
		declare out="$1"
		shift
		watermark_file "${param}" "${out}"
	elif [ "${param}" == "--silent" ]; then
		silent=1
	elif [ "${param}" == "--output-size" ]; then
		output_size="$1"
		check_working_size
		shift
	elif [ "${param}" == "--output-quality" ]; then
		output_quality="$1"
		shift
	elif [ -f "${param}" ]; then
		declare out="$(echo "${param}" | sed -E 's/(\.[^\.]*)?$/_marked\1/')"
		watermark_file "${param}" "${out}"
	elif [ -d "${param}" ]; then
		watermark_folder "${param}"
	elif [ "${param}" == "generate" ]; then
		render_watermark
	else
		printf -- "Can't understand parameter \"%s\"\n" "${param}"
		exit 1
	fi
done
