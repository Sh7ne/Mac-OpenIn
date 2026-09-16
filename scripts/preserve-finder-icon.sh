#!/bin/sh
set -eu

# Keep the original transparent artwork when Finder applies a background to
# legacy app icons. Store the same ICNS bytes as the bundle's custom icon.
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 app-path icon-path" >&2
    exit 1
fi

app_path=$1
icon_path=$2
if [ ! -d "$app_path/Contents" ] || [ ! -f "$icon_path" ]; then
    echo "The app bundle and original icon must exist." >&2
    exit 1
fi

icon_work_dir=$(mktemp -d "${TMPDIR:-/tmp}/open-in-code-icon.XXXXXX")
trap 'rm -f "$icon_work_dir/Original.icns" "$icon_work_dir/Icon.r"; rmdir "$icon_work_dir"' EXIT
cp "$icon_path" "$icon_work_dir/Original.icns"
cat > "$icon_work_dir/Icon.r" <<'RESOURCE'
read 'icns' (-16455) "Original.icns";
RESOURCE

custom_icon_path="$app_path/Icon$(printf '\r')"
xcrun Rez -s "$icon_work_dir" "$icon_work_dir/Icon.r" -o "$custom_icon_path"
xcrun SetFile -a V "$custom_icon_path"
xcrun SetFile -a C "$app_path"
touch "$app_path"
