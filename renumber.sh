#!/bin/bash

set -euo pipefail

### Logging

function fail {
	local -r msg="$*"
	printf >&2 -- "\x1b[31;1m[fail]\x1b[1m %s\x1b[0m\n" "$msg"
	exit 1
}

function warn {
	local -r msg="$*"
	printf >&2 -- "\x1b[33;1m[warn]\x1b[0m %s\n" "$msg"
}

function info {
	local -r msg="$*"
	printf >&2 -- "\x1b[36;1m[info]\x1b[0m %s\n" "$msg"
}

### Business

# Get EXIF date from file
function get_date {
	local -r file="$1"
	exiv2 -P v -K Exif.Photo.DateTimeOriginal pr "$file" 2>/dev/null
}

# Get directory name from space-split array (shift+join)
function get_dirname_from_parts {
	shift
	printf -- "%s" "$*"
}

# Find first file with given extension and EXIF timestamp and return timestamp
function get_date_of_first_ext {
	local -r dir="$1"
	local -r ext="$2"
	local file
	while read file; do
		datestr="$(get_date "$file" || true)"
		if [ "$datestr" ]; then
			printf -- "%s\n" "$datestr"
			return 0
		fi
	done < <(find "$dir" -maxdepth 1 -iname "*.$ext"; find "$dir" -iname "*.$ext")
	return 1
}

# Get EXIF timestamps of first NEF, JPG, JPEG files found and return oldest
function get_date_of_first {
	local -r dir="$1"
	local datestr
	local -r datestr_nef="$(get_date_of_first_ext "$dir" 'nef')"
	local -r datestr_jpg="$(get_date_of_first_ext "$dir" 'jpg')"
	local -r datestr_jpeg="$(get_date_of_first_ext "$dir" 'jpeg')"
	local -r datestr="$( printf -- "%s\n" "$datestr_nef" "$datestr_jpg" "$datestr_jpeg" | grep . | sort | head -n1 )"
	if [ -z "$datestr" ]; then
#		warn "Failed to find any images in $dir with DateTimeOriginal field"
		return 1
	fi
	printf -- "%s\n" "$datestr"
}

# Generate new name info for folder, return [num, date, name]
function get_new_name {
	local -r dir="$1"
	local -r datestr="$(get_date_of_first "$dir")"
	if [ -z "$datestr" ]; then
#		warn "Failed to get date for '$dir'"
		return 1
	fi
	local Y
	local M
	local D
	local h
	local m
	local s
	IFS=': /-' read Y M D h m s <<< "$datestr"
	printf -- "%s%s%s" "$Y" "$M" "$D"
}

function main {
	cd "$(dirname "$0")"
	local -r format="$1"
	local dir
	local date
	local -i dirnum
	local dirname
	local -i oldnum=-1
	local olddate=-1
	case "$format" in
	tsv) printf "%s\t%s\t%s\n" "old_number" "date" "name";;
	sh) printf '%s\n' \
		'#!/bin/bash' \
		'' \
		'set -euo pipefail' \
		'' \
		'cd "$(dirname "$0")"' \
		'' \
		'function move {' \
		'	local -r old="$1"' \
		'	local -r new="$2"' \
		'	if [ "${move:-}" ]; then' \
		'		mv -- "$old" "$new"' \
		'	else' \
		'		echo "mv -- \"$old\" \"$new\""' \
		'	fi' \
		'}' \
		''
		;;
	esac
	for dir in */; do
		dirnum="$(printf -- "%s\n" "$dir" | cut -f1 -d' ' | sed -e 's/^0*//')"
		if (( dirnum == 0 )); then
			warn "Skipping '$dir'"
			continue
		fi
		dirname="$(printf -- "%s\n" "$dir" | cut -f2- -d' ' | sed -e 's/\/$//')"
		if ! date="$(get_new_name "$dir")"; then
			warn "Failed to get new name for '$dir'"
			case "$format" in
			tsv) printf "%d\t%s\t%s\n" "$dirnum" "old_$dirnum" "$dirname";;
			sh) printf 'move "%s" "%s"\n' "$dir" "old_$dirnum $dirname";;
			esac
			continue
		fi
		if (( dirnum <= oldnum || date < olddate )); then
			warn "$(printf -- "Ordering violation: #%d, #%d / %s, %s" "$oldnum" "$dirnum" "$olddate" "$date")"
		fi
		case "$format" in
		tsv) printf "%d\t%s\t%s\n" "$dirnum" "$date" "$dirname";;
		sh) printf 'move "%s" "%s"\n' "$dir" "$date $dirname";;
		esac
		oldnum=$dirnum
		olddate=$date
	done
}

trap 'fail "Unknown error $?"' ERR

main tsv > renumber-date.gen.tsv
main sh > renumber-date.gen.sh 2>renumber-date.gen.log
