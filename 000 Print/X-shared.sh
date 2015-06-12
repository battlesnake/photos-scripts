declare -r config='X-shared.sh'

# Output paper size
declare -r output_size="a1"

# Calculate output  paper dimensions
declare -ra output_dims=( $(
	perl <(printf -- "%s;\n" \
		"\$_ = '${output_size}'" \
		'/^[aA](-?\d+)$/ or die "Unsupported paper size \"$_\"\n"' \
		'my $power = $1 / 2' \
		'print join(" ", map { $_ / 2**$power } qw(840 1188))'
	)
) )

# Name of index file
declare -r index="index"
# Name of comments backup file
declare -r comments_bak="comments.bak"
# Names of sizes
declare -ar sizes=( small large )
# EXIF data to add to index
declare -ar exif=( -CreateDate -ShutterSpeed -Aperture -FocalLength )
# Folder for annotated/resized images (intermediate)
declare -r annot_dir="annotated-resized"
# Output folder
declare -r output_dir="collage-${output_size}"
# Output image
declare -r output_image="${output_dir}/%02d.jpg"
# Layout image
declare -r layout_image="${output_dir}/layout.svg"

# Annotation fonts
declare -r description_font="$(dirname -- "$0")/../.fonts/Raleway-normal-500.ttf"
declare -r location_font="$(dirname -- "$0")/../.fonts/Open_Sans-italic-600.ttf"
declare -r date_font="$(dirname -- "$0")/../.fonts/Open_Sans-italic-600.ttf"
declare -r exif_font="$(dirname -- "$0")/../.fonts/Open_Sans-normal-400.ttf"

# Date color
declare -r date_color='#aaa'
# Exif color
declare -r exif_color='#ccc'

# Page size (mm)
declare -r page_width_mm="${output_dims[0]}"
declare -r page_height_mm="${output_dims[1]}"
# Border (mm)
declare -r border_mm=1
# Output outer margin (mm)
declare -r margin_mm=2.5
# Image padding (mm)
declare -r padding_mm=5
# Width of different output sizes (mm)
declare -r small_mm=140
declare -r large_mm=210
# Space between image and text (mm)
declare -r img_text_spacing_mm=4
# Description text height (mm)
declare -r description_size_mm=9
# Spacing between text blocks (mm)
declare -r text_block_spacing_mm=3
# Location text height (mm)
declare -r location_size_mm=6
# Date text height (mm)
declare -r date_size_mm=5
# Exif text height (mm)
declare -r exif_size_mm=4

# Preserve order of images in layout
declare -r preserve_order=no

# Calculate and truncate to integer
function calc {
	printf -- "(%s) / 1\n" "$*" | bc
}

# Image resolution (px/mm)
declare -r image_resolution=$(calc '300/25.4')

# Page size (px)
declare -r page_width=$(calc "${page_width_mm} * ${image_resolution}")
declare -r page_height=$(calc "${page_height_mm} * ${image_resolution}")
# Border (px)
declare -r border=$(calc "${border_mm} * ${image_resolution}")
# Margin (px)
declare -r margin=$(calc "${margin_mm} * ${image_resolution}")
# Image padding (px)
declare -r padding=$(calc "${padding_mm} * ${image_resolution}")
# Space between image and text (px)
declare -r img_text_spacing=$(calc "${img_text_spacing_mm} * ${image_resolution}")
# Width of different output sizes (px)
declare -r small=$(calc "${small_mm} * ${image_resolution}")
declare -r large=$(calc "${large_mm} * ${image_resolution}")
# Width of different image sizes (px)
declare -r small_img=$(calc "${small} - 2 * (${padding} + ${border})")
declare -r large_img=$(calc "${large} - 2 * (${padding} + ${border})")
# Description height (px)
declare -r description_size=$(calc "${description_size_mm} * ${image_resolution}")
# Description height (px)
declare -r location_size=$(calc "${location_size_mm} * ${image_resolution}")
# Spacing between text blocks (px)
declare -r text_block_spacing=$(calc "${text_block_spacing_mm} * ${image_resolution}")
# Date height (px)
declare -r date_size=$(calc "${date_size_mm} * ${image_resolution}")
# Exif height (px)
declare -r exif_size=$(calc "${exif_size_mm} * ${image_resolution}")

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
