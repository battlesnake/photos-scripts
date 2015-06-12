#!/bin/bash

set -euo pipefail

source 'X-shared.sh'

declare -i new_only=0

function can_skip {
	local description="$1"
	(( new_only )) && [ "${description}" ]
}

function get_value {
	local filename="$1"
	exif_cmd -Comment "${filename}"
}

function set_value {
	local filename="$1" value="$2"
	exif_cmd -Comment="${value}" "${filename}"
}

function process_file {
	local filename="$1"
	local old="$(get_value "${filename}")"
	if can_skip "${old}"; then
		errout "Skipping '%s'\n" "${filename}"
		continue
	fi
	read -erp "Comment for ${filename} >> " -i "${old}" description
	if [ "${description}" == "${old}" ]; then
		errout "Skipped '%s'\n" "${filename}"
	elif ! set_value "${filename}" "${description}"; then
		errout "Failed to annotate '%s'\n" "${filename}"
		exit 1
	fi
	errout "\n"
}

function is_filtered_out {
	local filename="$1"
	[ "${filter}" ] && ! echo "${filename}" |  grep -qP "${filter}"
}

function set_comments {
	(
		exec 3<"${index}"

		while IFS=$'\t' read -u 3 size width height date shutter aperature focallength filename; do
			if is_filtered_out "${filename}"; then
				continue
			fi
			process_file "${filename}"
		done
	)
}

function list_comments {
	(
		printf -- "%s\t%s\n" "Filename" "Comment"
		dump_comments
	) | column -t -s$'\t' -o'  |  '
}

function dump_comments {
	(
		exec 3<"${index}"

		while IFS=$'\t' read -u 3 size width height date shutter aperature focallength filename; do
			if is_filtered_out "${filename}"; then
				continue
			fi
			local comment="$(get_value "${filename}")"
			printf -- "%s\t%s\n" "${filename}" "${comment}"
		done
	)
}

function export_comments {
	dump_comments > "${comments_bak}"
}

function import_comments {
	(
		exec 3<"${comments_bak}"

		while ITF=$'\t' read -u 3 filename comment; do
			errout "%s <= %s\n" "${filename}" "${comment}"
			set_value "${filename}" "${comment}"
		done
	)
}

declare command=''
declare filter=''

function set_command {
	if [ "${command}" ]; then
		errout "Multiple commands specified\n"
		exit 1
	fi
	if (( "$2" )); then
		errout "Command must be last parameter\n"
		exit 1
	fi
	command="$1"
}

# Process parameters
while (( $# )); do
	declare param="$1"
	shift
	case "${param}" in
	--filter)
		if [ "${filter}" ]; then
			errout "Multiple filters specified\n"
			exit 1
		fi
		filter="$1"
		shift
		;;
	list)
		set_command list_comments $#
		;;
	set)
		set_command set_comments $#
		;;
	set-new)
		new_only=1
		set_command set_comments $#
		;;
	import)
		set_command import_comments $#
		;;
	export)
		set_command export_comments $#
		;;
	*)
		errout "Invalid parameter: %s\n" "${param}"
		exit 1
		;;
	esac
done

if [ -z "${command}" ]; then
	set_comment set_comments
fi

"${command}"
