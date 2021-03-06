#!/bin/bash

# Configure shell
set -euo pipefail
shopt -s nullglob

# Output directory base
declare out_base_dir="000 Collection"
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
declare -a watermark_opts=( --output-size 1280x1280\> --output-quality 47 --silent )
# Path to this script
declare self="$(realpath "$0")"
declare self_path="$(dirname "${self}")"
# Name of index HTML file
declare index_html="index.html"

cd "${self_path}"

source "./private-vars.sh"

function skip_line {
	printf -- "%s\n" "$*" | grep -qE '^#|^\s*$'
}

# Read FAVOURITES file and symlink referred files into OUTDIR folder
function update {
	mkdir -p -- "${out_base_dir}"

	local -i errs=0

	while read item; do
		if skip_line "${item}"; then
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
		if skip_line "${item}"; then
			continue
		fi
		local album="${item%% *}"
		local file="${item##*/}"
		local target="${out_base_dir}/${album}-${file}"
		if [ -h "${target}" -a ! -e "${target}" ]; then
			rm -- "${target}"
		fi
		if [ ! -e "${target}" ] && ! ln -sr "${item}" "${target}"; then
			errs=errs+1
			printf -- 'Failed to link "%s" to "%s"\n' "${item}" "${target}"
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
	test -e "${target}" && ! test "${target}" -ot "${item}" && \
		! ( test -e "${item}.pp3" && test "${target}" -ot "${item}.pp3" )
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
function make_index {(
	echo "Generating index"

	cd "${web_dir}"

	# Build database
	local -r tmpfile="$(mktemp)"
	local -i idx=0
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
		printf -- "%s\t%s\t%s\t%s\t%d\n" "${name}" "${group}" "${group_name}" "${group_id}" "$((++idx))"
	done > "${tmpfile}"

	(
		# Header
		printf -- '%s\n' \
			'<!doctype html>' '<html>' '<head>' \
			'<meta charset="utf-8">' \
			'<title>Mark'\''s photos</title>' \
			'<meta name="robots" content="none,noimageindex,noarchive,noindex,nofollow">' \
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
			'.gallery-item { margin: 10px; max-width: 28%; overflow: visible; }' \
			'.gallery-item a { border-radius: 15px; padding: 10px; background: #444; display: block; overflow: hidden; max-width: 100%; transition: transform 200ms ease-in; transform-origin center center; }' \
			'.gallery-item a:active, .gallery-item a:focus { transform: rotate(3deg); }' \
			'.gallery-item a:hover { transform: scale(1.1); }' \
			'.gallery-item img { border: 0; max-height: 280px; max-width: 100%; display: block; border-radius: 5px; }' \
			'@media (max-width: 1680px) {' \
			'.gallery-item img { max-height: 220px; }' \
			'}' \
			'@media (max-width: 1366px) {' \
			'.gallery-item a { margin: 5px; padding: 5px; border-radius:10px; }' \
			'.gallery-item img { max-height: 160px; }' \
			'}' \
			'@media (max-width: 960px) {' \
			'.gallery-item { margin: 5px; max-width: 45%; }' \
			'.gallery-item a { padding: 5px; border-radius: 10px; }' \
			'.gallery-item img { max-height: 100px; }' \
			'}' \
			'#viewer { position: fixed; z-index: 1000; top: 0; left: 0; right: 0; bottom: 0; margin: 0; padding: 0; background-color: #444; background-position: center center; background-size: contain; background-repeat: no-repeat; }' \
			'</style>' \
			'<script>' \
			'var lastViewed;' \
			'function openImage(anchor, event) {' \
			'for (var img=anchor.firstChild; img && img.nodeType!==1; img=img.nextSibling) ;' \
			'var viewer=document.getElementById("viewer");' \
			'if (!img || !viewer) return true;' \
			'viewer.style.backgroundImage = "url(" + img.src + ")";' \
			'viewer.classList.remove("hide");' \
			'viewer.focus();' \
			'if (event.preventDefault) event.preventDefault();' \
			'lastViewed=anchor;' \
			'return false;' \
			'}' \
			'function closeViewer(event) {' \
			'var viewer=document.getElementById("viewer");' \
			'if (!viewer) return;' \
			'viewer.classList.add("hide");' \
			'if (lastViewed) lastViewed.focus();' \
			'lastViewed=undefined;' \
			'if (event.preventDefault) event.preventDefault();' \
			'}' \
			'</script>' \
			'</head>' \
			'<body>' \
			'<header>' \
			'<h1>Mark'\''s travel photos</h1><small>Low-quality web versions</small>' \
			'<p>All content &copy; Mark K Cowan</p>' \
			'<p>Some photos may belong to the previous or next album rather than the
				one they appear in, I occasionally forget to create new folders on
				my camera when arriving in a new place...
				</p>' \
			'</header>' \
			'<div id="viewer" class="hide" onclick="closeViewer();" onkeypress="closeViewer();" tabindex="0"></div>'

cat <<'EOF'
<style>
.ui-loader {
	display: none !important;
}
.menu {
	list-style-type: none;
	display: flex;
	padding: 0em 2em 1em;
	flex-flow: row wrap;
	justify-content: center;
	align-items: stretch;
}
.menu-item {
	padding: 0.2em 0.4em 0.2em;
	border: 2px solid #222;
	background: #444;
	color: #ccc;
}
.menu-item:hover {
	background: #666;
	color: #fff;
}
</style>
<script>
function gotoAlbum(id) {
	var el = $('#album' + id);
	if (!el) {
		return;
	}
	el[0].scrollIntoView();
}
function gotoTop() {
	scrollTo(0, 0);
}
</script>
EOF

		# Write menu
		printf -- '%s\n' \
			'<nav class="menu-container">' \
			'<h2>A-Z index</h2>' \
			'<ul class="menu">'
		local last_group=''
		sort -k 3,3 < "${tmpfile}" | \
		while IFS=$'\t' read name group group_name group_id idx; do
			if [ "${group}" == "${last_group}" ]; then
				continue
			fi
			last_group="${group}"
			printf -- '%s\n' \
				"<li class=\"menu-item\" onclick=\"gotoAlbum(${idx}); event.preventDefault(); return false;\">" \
				"<a href=\""\#"album${idx}\">" \
				"${group_name}" \
				'</a>' \
				'</li>'
		done
		printf -- '%s\n' \
			'</ul>' \
			'</nav>'

		# Write image list
		printf -- '%s\n' \
			'<main>' \
			'<ul class="hide">'
		local last_group=''
		sort -s -t$'\t' -k4,4nr -k3,3d < "${tmpfile}" | \
		while IFS=$'\t' read name group group_name group_id idx; do
			if [ "${group}" != "${last_group}" ]; then
				last_group="${group}"
				printf -- '%s\n' \
					'</ul>' \
					"<h2 id=\"album${idx}\" onclick=\"gotoTop();\">" \
					"${group_name}" \
					"<a href=\"album${idx}\"></a>" \
					"</h2>" \
					'<ul class="gallery">'
			fi
			printf -- '%s\n' \
				'<li class="gallery-item">' \
				"<a href=\"${name}\" onclick=\"return openImage(this, event);\">" \
				"<img src=\"${name}\">" \
				'</a>' \
				'</li>'
		done
		printf -- '%s\n' \
			'</ul>' \
			'</main>'
		# Footer
		printf -- '%s\n' \
			'<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.4.0/css/font-awesome.min.css">' \
			'<link rel="stylesheet" href="http://hackology.co.uk/image-viewer/image-viewer.css">' \
			'<script src="http://hackology.co.uk/image-viewer/bower_components/jquery/jquery.js"></script>' \
			'<script src="http://hackology.co.uk/image-viewer/bower_components/jquery-mobile-bower/js/jquery.mobile-1.4.5.js"></script>' \
			'<script src="http://hackology.co.uk/image-viewer/image-viewer.js"></script>' \
			'<script>' \
			'$(".gallery-item a").removeAttr("onclick href target").prop("onclick", null).off("click");' \
			'$(".gallery-item img").imageViewer();' \
			'</script>' \
			'</body>' \
			'</html>'
	) > "${index_html}"
)}

# Upload web images and index HTML to server
function upload { (
	echo >&2 "Uploading"
	cd "${web_dir}"
	rsync -avzlr --delete --progress \
		*.${format} "${index_html}" \
		"${favourites_endpoint}"
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
case "${1:-}" in
--batch-callback)
	shift
	if [ "${TEST:-}" ]; then
		echo batch_callback "$@"
	else
		batch_callback "$@"
	fi
	;;
--command)
	shift
	while (( $# )); do
		declare cmd="$1"
		shift
		"${cmd}"
	done
	;;
'')
	main
	;;
*)
	printf >&2 -- "Unknown command: %s\n" "$1"
	;;
esac
