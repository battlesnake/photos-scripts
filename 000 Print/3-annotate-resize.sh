#!/bin/bash

set -euo pipefail
shopt -s nullglob

source 'X-shared.sh'

declare -ir concurrency=6

mkdir -p -- "${annot_dir}"

function format_caption {
	local -r data="$1"
	local -ir field="$2"
	printf -- "%s" "${data}" | \
	perl -n <(printf -- "%s\n" \
		'/^(.*)\s\(([^\(]+)\)$/ or' \
		'/^(.*), ([^,\(]+)$/ or' \
		'/^(.*)()$/ and print STDERR "Failed to parse comment: $_\n";' \
		"print \$${field};"
	)
}

function process_file {
	local -r src="$1" size="$2"
	local -ir width="$3" height="$4" datestamp="$5"
	local -r shutter="${6}s"
	local -r aperture="f/$(echo "$7" | perl -pe 's/\.0$//g')"
	local -r focallength="$(echo "$8" | perl -pe 's/(\.0+)?mm$//g')mm"
	local -r target="${annot_dir}/${src##*/}"
	# Dirty checking
	if (( force == 0 )) && up_to_date "${src}" "${target}" && up_to_date "${config}" "${target}"; then
		errout '·'
		return
	fi
	# Get geometry for this image size
	eval local -r block_w="\$${size}"
	eval local -r img_w="\$${size}_img"
	# Get strings for this image
	local -r comment="$(exif_cmd -Comment "${src}")"
	local -r description="$(format_caption "${comment}" 1)"
	local -r location="$(format_caption "${comment}" 2)"
	local -r date="$(date --date=@"${datestamp}" +'%B %Y')"
	local -r exiftext="$(printf -- "%s\n%s @ %s" "${focallength}" "${shutter}" "${aperture}")"
	# Render
	magick \
		-background white \
		\( \
			"${src}" \
			-resize "${img_w}x" \
		\) \
		\( \
			-size "1x${img_text_spacing}" xc:none \
		\) \
		\( \
			\( \
				-size "${img_w}x" \
				-fill black -stroke none \
				-density 72 -pointsize "${description_size}" \
				-font "${description_font}" \
				-gravity center \
				caption:"${description}" \
			\) \
			\( \
				-size "1x${text_block_spacing}" xc:none \
			\) \
			\( \
				-size "${img_w}x" \
				-fill black -stroke none \
				-density 72 -pointsize "${location_size}" \
				-font "${location_font}" \
				-gravity center \
				caption:"${location}" \
			\) \
			-gravity center \
			-append \
			-fill "${date_color}" \
			-font "${date_font}" \
			-gravity southeast \
			-density 72 -pointsize "${date_size}" \
			-annotate 0 "${date}" \
			-fill "${exif_color}" \
			-font "${exif_font}" \
			-gravity southwest \
			-density 72 -pointsize "${exif_size}" \
			-annotate 0 "${exiftext}" \
		\) \
		-gravity center -append \
		-bordercolor white -border "${padding}x${padding}" \
		-bordercolor black -border "${border}x${border}" \
		-bordercolor white -border "${margin}x${margin}" \
		-quality 100 \
		-resize "${block_w}x" \
		"${target}"
	errout 'x'
}

if (( $# )) && [ "$1" == '--batch-callback' ]; then
	shift
	process_file "$8" "$1" "$2" "$3" "$4" "$5" "$6" "$7"
	exit
fi

declare -i force=0

while (( $# )); do
	declare param="$1"
	shift
	case "${param}" in
	-f) ;&
	--force)
		force=1
		;;
	*)
		errout "Unknown parameter: '%s'\n" "${param}"
		exit 1
		;;
	esac
done

export force

nice xargs -a "${index}" -P${concurrency} -x -n8 \
	"$0" --batch-callback
printf -- "\n"
