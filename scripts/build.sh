#!/bin/sh
set -eu

configuration=${1:-Release}
case "$configuration" in
    Debug|Release) ;;
    *) echo "Usage: $0 [Debug|Release]" >&2; exit 1 ;;
esac

repo_path=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
build_path="$repo_path/build"

# Keep Xcode's signing input separate from the finished app's Finder metadata.
xcodebuild -project "$repo_path/Open in VSCode.xcodeproj" \
    -scheme "Open in Code" \
    -configuration "$configuration" \
    -destination 'generic/platform=macOS' \
    -derivedDataPath "$build_path/DerivedData" \
    build

signed_app="$build_path/DerivedData/Build/Products/$configuration/Open in Code.app"
codesign --verify --strict "$signed_app"
if [ "$(lipo -archs "$signed_app/Contents/MacOS/Open in Code")" != arm64 ]; then
    echo "The executable must contain only arm64." >&2
    exit 1
fi

app_path="$build_path/Build/Products/$configuration/Open in Code.app"
mkdir -p "$(dirname -- "$app_path")"
ditto "$signed_app" "$app_path"
sh "$repo_path/scripts/preserve-finder-icon.sh" "$app_path" "$repo_path/Monterey.icns"
# Finder custom icons are added after signing, like a Get Info icon change.
# Normal signature verification supports them; --strict forbids Finder metadata.
codesign --verify "$app_path"

if [ "$configuration" = Release ]; then
    app_version=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$app_path/Contents/Info.plist")
    archive_path="$build_path/Open-in-Code-$app_version-arm64.zip"
    # Archive a containing directory: --keepParent alone drops the top-level
    # app's FinderInfo, losing the custom icon when the ZIP is extracted.
    archive_work_dir=$(mktemp -d "$build_path/.archive.XXXXXX")
    trap 'rm -rf "$archive_work_dir"' EXIT
    ditto "$app_path" "$archive_work_dir/Open in Code.app"
    ditto -c -k --sequesterRsrc "$archive_work_dir" "$archive_path"
    echo "Archive: $archive_path"
fi
echo "App: $app_path"
