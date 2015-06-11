#!/bin/bash

set -euo pipefail

declare -a fonts=( "Open+Sans:300,400,600,700,400italic,600italic" "Raleway:400,500" )

function get_font_css {
	declare name="$*"
	echo >&2 "$(echo "${name}" | perl -pe 's/\+/ /g;s/:.*$//')"
	curl -s "http://fonts.googleapis.com/css?family=${name}"
}

function extract_font_url {
	"$(dirname "$0")/css-parser.pl"
}

function download_ttf {
	while read name; do
		read url
		wget -q "${url}" -O "${name}.ttf"
	done
}

for font in "${fonts[@]}"; do
	get_font_css "${font}" | extract_font_url | download_ttf
done
