#!/bin/bash

set -euo pipefail

declare self="$(realpath "$0")"
declare watermark="$(dirname "${self}")/watermark.sh"

declare tmp_format="bmp"

declare ffmpeg="eval nice /usr/bin/ffmpeg -loglevel warning -y </dev/null"
declare magick

declare config_file="timelapse.cfg"

# Get name of imagemagick
if which magick 2>/dev/null >/dev/null; then
	magick=magick
elif which convert 2>/dev/null >/dev/null; then
	magick=convert
else
	echo >&2 "Imagemagick not found"
	exit 1
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

function paths {
	readvalue "Temporary folder name (frames)" "validate_name" "temporary folder"
	readvalue "Output folder name (video)" "validate_name" "output folder"
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
	touch "${config_file}"
	(
		< "${config_file}" grep -vP "^${key}=" || true
		echo "${key}=${val}"
	) | sort > timelapse.tmp
	mv timelapse.{tmp,cfg}
}

function getval {
	local key="$1"
	touch "${config_file}"
	< "${config_file}" grep -P "^${key}=" | sed -E "s/^${key}=//" || getval_default "$1"
}

function getval_default {
	local key="$1"
	case "${key}" in
	"temporary folder") echo "tmp";;
	"output folder") echo "out";;
	esac
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
	local tmpdir="$(getval "temporary folder")"
	local out="$(echo "$1" | grep -Po "\d{4}" | head -n 1).${tmp_format}"
	local size="$(getval "sizes" | cut -f1 -d\ )"
	local width="$(echo "$size" | cut -f1 -dx)"
	local height="$(echo "$size" | cut -f2 -dx)"
	local crop_gravity="$(getval "crop gravity")"
	local cropped="${tmpdir}/crop-${out}" marked="${tmpdir}/wm-${out}"
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
	mkdir -p "${tmpdir}"
	nice "${magick}" "${frame}" \
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
	local outdir="$(getval "output folder")"
	local tmpdir="$(getval "temporary folder")"
	local rate="$(getval "rates" | cut -f1 -d\ )"
	local start_index="$(getval "start index")"
	local src=( -r "${rate}" -start_number "${start_index}" -i "${tmpdir}/wm-%04d.${tmp_format}" )
	local video_opts=( -c:v libx264 -crf 0 -pix_fmt yuv444p )
	local proj_video_opts=( $(getval "extra master ffmpeg options" ) )
	title "Rendering master video"
	mkdir -p "${outdir}"
	${ffmpeg} \
		"${src[@]}" \
		"${video_opts[@]+${video_opts[@]}}" \
		"${proj_video_opts[@]+${proj_video_opts[@]}}" \
		"${outdir}/master.mp4"
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
	local outdir="$(getval "output folder")"
	local bitrate="$1" size="$2" rate="$3" size_name
	local project_name="$(getval "project name")"
	local src=( -r "${rate}" -i "${outdir}/master.mp4" )
	local out_mp4=( -c:v libx264 -pix_fmt yuv420p -preset slow -profile:v baseline -movflags faststart )
	local out_ogg=( -c:v libtheora )
	local out_webm=( -c:v libvpx )
	case "${size}" in
	2048x1080) size_name="2k";;
	4096x2160) size_name="4k";;
	3840x2160) size_name="uhd";;
	1920x1080) size_name="hd1080";;
	1280x720) size_name="hd720";;
	1024x768) size_name="xga";;
	*) size_name="${size}";;
	esac
	local opts=( -s "${size}" -r "${rate}" -b:v "${bitrate}k" -an )
	local out_name="${outdir}/${project_name}-${size_name}-${rate}-${bitrate}"
	title "Rendering ${size}@${rate}Hz@${bitrate}kbit/s video"
	${ffmpeg} \
		"${src[@]}" \
		"${opts[@]+${opts[@]}}" \
		"${out_mp4[@]+${out_mp4[@]}}" \
		"${out_name}.mp4"
	${ffmpeg} \
		"${src[@]}" \
		"${opts[@]+${opts[@]}}" \
		"${out_webm[@]+${out_webm[@]}}" \
		"${out_name}.webm"
	${ffmpeg} \
		"${src[@]}" \
		"${opts[@]+${opts[@]}}" \
		"${out_ogg[@]+${out_ogg[@]}}" \
		"${out_name}.ogv"
}

# Remove temporary folder
function rmtmp {
	local tmpdir="$(getval "temporary folder")"
	title "Removing temporary files"
	[ "${tmpdir}" ] && rm -rf -- "${tmpdir}"
}

# Remove temporary folder and output folder
function full_reset {
	local tmpdir="$(getval "temporary folder")"
	local outdir="$(getval "output folder")"
	title "Removing temporary and output files"
	[ "${tmpdir}" ] && [ "${outdir}" ] && rm -rf -- "${tmpdir}" "${outdir}"
}

# Display command line help
function help {
	title "Help"
	echo "./$(basename "$0") [comand] [command] [...]"
	echo "Commands:"
	echo "  using - Next parameter specifies configuration file (default: timelapse.cfg)"
	echo "  configure - Configure the timelapse"
	echo "  paths - Change the paths for temporary / output files"
	echo "  frames - process the source frames"
	echo "  master - render the master video"
	echo "  render - transcode the final videos from the master"
	echo "  rmtmp - remove temporary folder"
	echo "  full-reset - remove temporary folder and output folder"
	echo ""
	echo "  Only 'configure' and 'paths' require user interaction."
	echo ""
	echo "Typical usage:"
	echo "  ./$(basename "$0") configure frames master render"
	echo ""
	echo "  This configures the timelapse, processes the frames, renders the"
	echo "  master video, then transcodes it to the target sizes/bitrates"
	echo ""
	echo "Configuration:"
	echo "  This is stored in the configuration file.  The default file if none"
	echo "  is specified via the 'using' clause is 'timelapse.cfg'.  The file"
	echo "  is plain-text key=value format and will be created if it does not"
	echo "  exist already."
	echo ""
	echo "  Example: If I want two separate configurations, one for the original"
	echo "  timelapse and one for the noise-reduced one:"
	echo ""
	echo "  ./$(basename "$0") using timelapse-orig.cfg configure paths frames"
	echo ""
	echo "  This configures the first timelapse and stores the configuration to"
	echo "  timelapse-orig.fg."
	echo "  It also configures the paths for temporary and output files, so we"
	echo "  can share the same temporary folder as the denoised timelapse, but"
	echo "  avoid overwriting the output from it."
	echo "  It then processes the frames, scaling and watermarking as needed."
	echo ""
	echo "  ./$(basename "$0") using timelapse-nr.cfg configure paths"
	echo ""
	echo "  This configures the second timelapse, storing the configuration to"
	echo "  timelapse-nr.cfg.  We specify our noise-reduction filters via the"
	echo "  'Extra FFMPEG options for master render' option when asked."
	echo "  It configures the paths, so we can share the same temporary folder"
	echo "  as the first timelapse but output to a different folder."
	echo "  We don't need to specify the 'frames' command, since this generates"
	echo "  temporary files that are shared by the first timelapse."
	echo ""
	echo "  ./$(basename "$0") using timelapse-orig.cfg master render"
	echo "  ./$(basename "$0") using timelapse-nr.cfg master render"
	echo ""
	echo "  Masters and renders each timelapse, using the same pre-processed"
	echo "  temporary files for both, but writing the outputs to two separate"
	echo "  folders."
	exit 1
}

# Read command line parameters
if ! (( $# )); then
	set help
fi

declare param arg key val

if (( $# )) && [ "$1" == "using" ]; then
	shift
	config_file="$1"
	shift
fi

while (( $# )); do
	param="$1"
	shift
	case "${param}" in
	using) echo '"using" must be first parameter if specified' >&2; exit 1;;
	configure) ;&
	config) config;;
	paths) paths;;
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
