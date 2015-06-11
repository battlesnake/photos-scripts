# Name of index file
declare -r index="index"
# Name of comments backup file
declare -r comments_bak="comments.bak"
# Names of sizes
declare -ar sizes=( small large )
# EXIF data to add to index
declare -ar exif=( -CreateDate -ShutterSpeed -Aperture -ISO )
# Folder for annotated/resized images (intermediate)
declare -r annot_dir="annotated-resized"
# Output image
declare -r output_image="collage.jpg"

# Annotation fonts
declare -r description_font="$(dirname "$0")/../.fonts/Raleway-normal-500.ttf"
declare -r location_font="$(dirname "$0")/../.fonts/Open_Sans-italic-600.ttf"

# Page width
declare -r page_width_mm=840
# Border (mm)
declare -r border_mm=1
# Output outer margin (mm)
declare -r margin_mm=5
# Image padding (mm)
declare -r padding_mm=10
# Width of different output sizes (mm)
declare -r small_mm=120
declare -r large_mm=200
# Space between image and text (mm)
declare -r img_text_spacing_mm=7
# Description text height (mm)
declare -r description_size_mm=10
# Spacing between text blocks (mm)
declare -r text_block_spacing_mm=5
# Location text height (mm)
declare -r location_size_mm=7

# Image resolution (px/mm)
declare -r image_resolution=$(echo '300/25.4' | bc -l)

# Page width (px)
declare -r page_width=$(echo "${page_width_mm} * ${image_resolution}" | bc -l)
# Border (px)
declare -r border=$(echo "${border_mm} * ${image_resolution}" | bc -l)
# Margin (px)
declare -r margin=$(echo "${margin_mm} * ${image_resolution}" | bc -l)
# Image padding (px)
declare -r padding=$(echo "${padding_mm} * ${image_resolution}" | bc -l)
# Space between image and text (px)
declare -r img_text_spacing=$(echo "${img_text_spacing_mm} * ${image_resolution}" | bc -l)
# Width of different output sizes (px)
declare -r small=$(echo "${small_mm} * ${image_resolution}" | bc -l)
declare -r large=$(echo "${large_mm} * ${image_resolution}" | bc -l)
# Width of different image sizes (px)
declare -r small_img=$(echo "${small} - 2 * (${padding} + ${border})" | bc -l)
declare -r large_img=$(echo "${large} - 2 * (${padding} + ${border})" | bc -l)
# Description height (px)
declare -r description_size=$(echo "${description_size_mm} * ${image_resolution}" | bc -l)
# Description height (px)
declare -r location_size=$(echo "${location_size_mm} * ${image_resolution}" | bc -l)
# Spacing between text blocks (px)
declare -r text_block_spacing=$(echo "${text_block_spacing_mm} * ${image_resolution}" | bc -l)


function exif_cmd {
	exiftool -veryShort -tab -q  -dateFormat '%s' "$@"
}

function up_to_date {
	local src="$(readlink -f "$1")" dest="$(readlink -f "$2")"
	test -e "${dest}" && ! test "${dest}" -ot "${src}"
}

function errout {
	printf >&2 -- "$@"
}

# Exports
export annot_dir output_image page_width
