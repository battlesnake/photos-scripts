#!/bin/bash

function help {
	echo "Finds all folders containing a configured timelapse, and runs the timelapse"
	echo "script in those folders with the given commands."
	echo ""
	echo "Example:"
	echo ""
	echo "  To re-configure all timelapses"
	echo "  ./re-timelapse config"
	echo ""
	echo "  To re-run all timelapses, discarding intermediate data from previous runs"
	echo "  ./re-timelapse rmtmp frames master render"
	echo ""
	echo "  Like above, but delete output of previous runs too"
	echo "  ./re-timelapse full-reset frames master render"
}

set -euo pipefail

declare exclude=''
declare from=''
declare filter=''
declare -i dry=0

declare arg
while (( $# )) && [[ "$1" =~ ^-- ]]; do
	arg="${1:2}"
	shift
	case "${arg}" in
	exclude)
		exclude="$1"
		shift
		;;
	from)
		from="$1"
		shift
		;;
	filter)
		filter="$1"
		shift
		;;
	dry)
		dry=1
		;;
	*)
		printf -- 'Unknown parameter: --%s\n' "${arg}"
		exit 1
		;;
	esac
done

if ! (( $# )); then
	printf -- "No commands specified\n\n"
	help
	exit 1
fi

declare timelapse="$(realpath "$(dirname "$0")/timelapse.sh")"

declare -a timelapses=( "" )
IFS=$'\n' timelapses=( $(find . -name 'timelapse.cfg' | sort -n) )

declare cfg
declare dir

for cfg in "${timelapses[@]}"; do
	dir="$(dirname "${cfg}")"
	if [ "${filter}" ] && echo "${cfg}" | grep -qvP "${filter}"; then
		printf -- "\e[1mFiltered out: \e[0m%s\n" "${dir}"
		continue;
	fi
	if [ "${from}" ]; then
		if echo "${cfg}" | grep -qP "${from}"; then
			from=
		else
			printf -- "\e[1mSkipped: \e[0m%s\n" "${dir}"
			continue
		fi
	fi
	if [ "${exclude}" ] && echo "${cfg}" | grep -qP "${exclude}"; then
		printf -- "\e[1mExcluded: \e[0m%s\n" "${dir}"
		continue
	fi
	(
		cd "${dir}"
		printf -- "\e[1mEntering \e[0m%s\n" "${dir}"
		if ! (( dry )); then
			"${timelapse}" "$@"
			printf -- "\n"
		fi
	)
done
