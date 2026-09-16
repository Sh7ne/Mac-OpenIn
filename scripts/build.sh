#!/bin/sh
set -eu

configuration=${1:-Release}
product=${2:-All}
if [ "$#" -gt 2 ]; then
    echo "Usage: $0 [Debug|Release] [All|Code|Terminal]" >&2
    exit 1
fi
case "$configuration" in
    Debug|Release) ;;
    *) echo "Usage: $0 [Debug|Release] [All|Code|Terminal]" >&2; exit 1 ;;
esac

repo_path=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
build_path="$repo_path/build"
case "$product" in
    All)
        sh "$0" "$configuration" Code
        sh "$0" "$configuration" Terminal
        if [ "$configuration" = Release ]; then
            app_version=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' \
                "$build_path/Build/Products/Release/Open in Code.app/Contents/Info.plist")
            hdiutil create -ov -format UDZO -volname "Open in Code & Terminal" \
                -srcfolder "$build_path/Build/Products/Release" \
                "$build_path/Open-in-$app_version-arm64.dmg"
        fi
        exit 0
        ;;
    Code)
        product_name="Open in Code"
        icon_path="$repo_path/Monterey.icns"
        archive_name="Open-in-Code"
        ;;
    Terminal)
        product_name="Open in Terminal"
        icon_path="$repo_path/Terminal/Terminal.icns"
        archive_name="Open-in-Terminal"
        ;;
    *) echo "Usage: $0 [Debug|Release] [All|Code|Terminal]" >&2; exit 1 ;;
esac

# Keep Xcode's signing input separate from the finished app's Finder metadata.
xcodebuild -quiet -project "$repo_path/Open in VSCode.xcodeproj" \
    -scheme "$product_name" \
    -configuration "$configuration" \
    -destination 'generic/platform=macOS' \
    -derivedDataPath "$build_path/DerivedData" \
    build

signed_app="$build_path/DerivedData/Build/Products/$configuration/$product_name.app"
codesign --verify --strict "$signed_app"
if [ "$(lipo -archs "$signed_app/Contents/MacOS/$product_name")" != arm64 ]; then
    echo "The executable must contain only arm64." >&2
    exit 1
fi

app_path="$build_path/Build/Products/$configuration/$product_name.app"
mkdir -p "$(dirname -- "$app_path")"
# Replace the generated bundle so removed resources cannot survive a rebuild.
rm -rf "$app_path"
ditto "$signed_app" "$app_path"
sh "$repo_path/scripts/preserve-finder-icon.sh" "$app_path" "$icon_path"
# Finder custom icons are added after signing, like a Get Info icon change.
# Normal signature verification supports them; --strict forbids Finder metadata.
codesign --verify "$app_path"

if [ "$configuration" = Release ]; then
    app_version=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$app_path/Contents/Info.plist")
    archive_path="$build_path/$archive_name-$app_version-arm64.zip"
    # Archive a containing directory: --keepParent alone drops the top-level
    # app's FinderInfo, losing the custom icon when the ZIP is extracted.
    archive_work_dir=$(mktemp -d "$build_path/.archive.XXXXXX")
    trap 'rm -rf "$archive_work_dir"' EXIT
    ditto "$app_path" "$archive_work_dir/$product_name.app"
    ditto -c -k --sequesterRsrc "$archive_work_dir" "$archive_path"
    echo "Archive: $archive_path"
fi
echo "App: $app_path"
