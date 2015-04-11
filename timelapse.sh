#!/bin/bash

set -euo pipefail

declare self="$(realpath "$0")"
declare watermark="$(dirname "${self}")/watermark.sh"

declare tmp_format="bmp"

declare ffmpeg="eval /usr/bin/ffmpeg -loglevel warning -y </dev/null"
declare magick="/usr/bin/magick"

if ! [ -e "${magick}"  ]; then
	magick="/usr/bin/convert"
fi

function title {
	printf "\e[1m%s\e[0m\n" "$*"
}

# Configuration
function config {
	local format rates sizes
	title "Configuration"
	printf "The resolution for the master file is the first resolution given\n"
	readvalue "Project name" "validate_name" "project name"
	readvalue "Frame format (e.g. bmp/jpg/png)" "validate_format" "format"
	readvalue "First frame index" "validate_integer" "start index"
	readvalue "Crop gravity (\"squash\" for no crop)" "true" "crop gravity"
	readvalues "Target video frame-rate(s)" "validate_number" "rates"
	readvalues "Target video resolution(s)" "validate_size" "sizes"
	readvalues "Target video bit-rate(s) (kbit/s)" "validate_number" "bitrates"
	readvalue "Extra FFMPEG options for master render" "true" "extra master ffmpeg options"
}

function readvalue {
	local prompt="$1" validator="$2" key="$3" value
	while true; do
		read -p " * ${prompt}: " -ei "$(getval "${key}")" value
		if "${validator}" ${value}; then
			break
		fi
		printf "Invalid value: %s\n" "${value}"
	done
	setval "${key}" "${value}"
}

function readvalues {
	local prompt="$1" validator="$2" key="$3" values
	while true; do
		printf " * %s: " "${prompt}"
		read -ei "$(getval "${key}")" values
		if checkall "${validator}" ${values}; then
			break
		fi
		printf "Invalid values: %s\n" "${values}"
	done
	setval "${key}" "${values}"
}

function setval {
	local key="$1" val="$2"
	touch timelapse.cfg
	(
		< timelapse.cfg grep -vP "^${key}=" || true
		echo "${key}=${val}"
	) | sort > timelapse.tmp
	mv timelapse.{tmp,cfg}
}

function getval {
	local key="$1"
	touch timelapse.cfg
	< timelapse.cfg grep -P "^${key}=" | sed -E "s/^${key}=//" || true
}

function checkall {
	local validator="$1" value
	shift
	if ! (( $# )); then
		return 1
	fi
	for value in "$@"; do
		if ! "${validator}" "${value}"; then
			return 1
		fi
	done
}

function validate_name {
	echo "$*" | grep -qxP '[a-z][a-z0-9-]*?[a-z0-9]'
}

function validate_format {
	local format="$1"
	[ "${format}" ] && ls *.${format} 2>/dev/null 1>/dev/null
}

function validate_integer {
	echo "$*" | grep -qxP '\d+'
}

function validate_number {
	echo "$*" | grep -qxP '\d+(\.\d+)?'
}

function validate_size {
	echo "$*" | grep -qxP '(\d+x\d+)'
}

# Crop original frames and watermark
function processframes {
	local frame format="$(getval "format")"
	local frames=( *.${format} )
	local done=0 count="${#frames[@]}"
	local parallel=1
	if ! (( parallel )); then
		title "Processing frames *.${format}"
		for frame in "${frames[@]}"; do
			(( done++ )) || true
			printf -- "\r%s/%s (%s%%)   \r" "${done}" "${count}" "$(( done * 100 / count ))"
			processframe "${frame}"
		done
		printf -- "\r                      \r"
	else
		title "Processing ${count} frames *.${format}"
		printf -- "%s\0" "${frames[@]}" | \
			xargs -0 -n1 -P3 -I{} "${self}" processframe {}
		printf -- '\n'
	fi
}

# Crop frame and watermark
function processframe {
	local frame="$1"
	local out="$(echo "$1" | grep -Po "\d{4}" | head -n 1).${tmp_format}"
	local size="$(getval "sizes" | cut -f1 -d\ )"
	local width="$(echo "$size" | cut -f1 -dx)"
	local height="$(echo "$size" | cut -f2 -dx)"
	local crop_gravity="$(getval "crop gravity")"
	local cropped="tmp/crop-${out}" marked="tmp/wm-${out}"
	local fit=( "" )
	if [ "${crop_gravity}" == "squash" ]; then
		fit=(
			-unsharp "2x0.5+0.7+0"
			-resize "${size}!"
		)
	else
		fit=(
			-resize "$((2*width))x"
			-resize "x$((2*height))<"
			-unsharp "2x0.5+0.7+0"
			-resize "50%"
			-gravity "${crop_gravity}"
			-crop "${size}+0+0" +repage
		)
	fi
	# printf -- "Processing frame \"%s\" => \"%s\"\n" "${frame}" "${marked}"
	mkdir -p "tmp"
	${magick} "${frame}" \
		"${fit[@]}" \
		"${cropped}"
	"${watermark}" --silent \
		--output-quality 100 \
		--output-size "${size}" \
		"${cropped}" to "${marked}"
	rm -- "${cropped}"
	printf -- '.'
}

# Render high-res, high-quality video
function master {
	local rate="$(getval "rates" | cut -f1 -d\ )"
	local start_index="$(getval "start index")"
	local src=( -r "${rate}" -start_number "${start_index}" -i "tmp/wm-%04d.${tmp_format}" )
	local video_opts=( -c:v libx264 -crf 0 -pix_fmt yuv444p )
	local proj_video_opts=( $(getval "extra master ffmpeg options" ) )
	title "Rendering master video"
	mkdir -p "out"
	${ffmpeg} \
		"${src[@]}" \
		"${video_opts[@]}" \
		"${proj_video_opts[@]}" \
		"out/master.mp4"
}

# Transcode the master video lower-res / lower-quality for web browsers
function output {
	local sizes=( $(getval "sizes") )
	local rates=( $(getval "rates") )
	local bitrates=( $(getval "bitrates") )
	local size rate bitrate
	for bitrate in "${bitrates[@]}"; do
		for size in "${sizes[@]}"; do
			for rate in "${rates[@]}"; do
				output_one "${bitrate}" "${size}" "${rate}"
			done
		done
	done
}

function output_one {
	local bitrate="$1" size="$2" rate="$3" size_name
	local project_name="$(getval "project name")"
	local src=( -r "${rate}" -i "out/master.mp4" )
	local out_mp4=( -c:v libx264 -pix_fmt yuv420p -preset slow -profile:v baseline -movflags faststart )
	local out_ogg=( -c:v libtheora )
	local out_webm=( -c:v libvpx )
	case "${size}" in
	1920x1080) size_name="hd1080";;
	1280x720) size_name="hd720";;
	1024x768) size_name="xga";;
	*) size_name="${size}";;
	esac
	local opts=( -s "${size}" -r "${rate}" -b:v "${bitrate}k" -an )
	local out_name="out/${project_name}-${size_name}-${rate}-${bitrate}"
	title "Rendering ${size}@${rate}Hz@${bitrate}kbit/s video"
	${ffmpeg} \
		"${src[@]}" \
		"${opts[@]}" \
		"${out_mp4[@]}" \
		"${out_name}.mp4"
	${ffmpeg} \
		"${src[@]}" \
		"${opts[@]}" \
		"${out_webm[@]}" \
		"${out_name}.webm"
	${ffmpeg} \
		"${src[@]}" \
		"${opts[@]}" \
		"${out_ogg[@]}" \
		"${out_name}.ogv"
}

# Remove temporary folder
function rmtmp {
	title "Removing temporary files"
	rm -rf -- tmp
}

# Remove temporary folder and output folder
function full_reset {
	title "Removing temporary and output files"
	rm -rf -- tmp out
}

# Display command line help
function help {
	title "Help"
	echo "./$(basename "$0") [comand] [command] [...]"
	echo "Commands:"
	echo "  configure - Configure the timelapse"
	echo "  frames - process the source frames"
	echo "  master - render the master video"
	echo "  render - transcode the final videos from the master"
	echo "  rmtmp - remove temporary folder"
	echo "  full-reset - remove temporary folder and output folder"
	echo ""
	exit 1
}

# Read command line parameters
if ! (( $# )); then
	set configure frames master render
fi

declare param arg key val
while (( $# )); do
	param="$1"
	shift
	case "${param}" in
	configure) ;&
	config) config;;
	process) ;&
	processframes) ;&
	frames) processframes;;
	master) master;;
	render) output;;
	clean) ;&
	rmtmp) rmtmp;;
	full-reset) full_reset;;
	processframe)
		arg="$1"
		shift
		processframe "${arg}"
		;;
	set)
		key="$1"
		shift
		val="$1"
		shift
		setval "${key}" "${val}"
		;;
	get)
		key="$1"
		shift
		getval "${key}"
		;;
	help) ;&
	-h) ;&
	--help) help;;
	*) echo "Unrecognised command \"${param}\""; echo ""; help;;
	esac
done
