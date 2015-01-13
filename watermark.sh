#!/bin/bash

set -euo pipefail

declare output_quality="55"
declare output_size="900x"

declare batch_out="marked"

declare text="hackology.co.uk"
declare text_font="/cygdrive/c/Windows/Fonts/OpenSans-Bold.ttf"
declare text_size="55"
declare text_color="#0004"
declare bg_color="white"

declare wm_file="/tmp/wm.png"
declare wm_width="500"
declare wm_height="100"
declare wm_radius="50"
declare wm_offset="+75+0"
declare wm_origin="southeast"

declare working_size="2400x"

declare silent=0

function render_watermark {
	if ! (( silent )); then
		printf -- "Rendering watermark to \"%s\"\n" "${wm_file}" >&2
	fi
	rm -f "${wm_file}"
	magick \
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
		"${wm_file}"
}

function watermark_needed {
	if ! [ -e "${wm_file}" ]; then
		render_watermark
	fi
}

function watermark_file {
	watermark_needed
	local in="$1" out="$2"
	if ! (( silent )); then
		printf -- "\e[37m%s\e[37m => \e[32m%s\e[37m\n" "${in##*/}" "${out}" >&2
	fi
	magick \
		\( \
			\( "${in}" -resize "${working_size}" -unsharp "2x0.5+0.7+0" \) \
			\( "${wm_file}" -geometry "${wm_offset}" -gravity "${wm_origin}" \) \
			-compose "atop" -composite \
		\) \
		-resize "${output_size}" \
		-quality "${output_quality}" \
		"${out}"
}

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
