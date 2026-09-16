# Open in Code

Open the current Finder folder in Visual Studio Code with one click from the Finder toolbar.

**Version 2.0 requires Apple Silicon (arm64) and macOS 12.1 or later. Intel Macs are not supported.**

The application is named **Open in Code.app** and keeps the original transparent toolbar icon.

## How it works

- Select a folder to open that folder in Visual Studio Code.
- Select a file to open its containing folder.
- With nothing selected, open the folder shown in the front Finder window.

Visual Studio Code must be installed. The `code` command-line launcher is not required.

## Build from source

Install full Xcode with a macOS SDK that supports arm64. Run these commands to clone and build:

```sh
git clone https://github.com/Sh7ne/Mac-OpenInVSCode.git
cd Mac-OpenInVSCode
sh scripts/build.sh
```

| Output | Location |
| --- | --- |
| Application | `build/Build/Products/Release/Open in Code.app` |
| ZIP package | `build/Open-in-Code-2.0-arm64.zip` |

For a Debug build, run `sh scripts/build.sh Debug`. Its application is generated in
`build/Build/Products/Debug`.

Both configurations build only arm64, and the source rejects non-arm64 compilation.
The application uses an ad hoc signature for local use and is not notarized.

## Installation and usage

1. Build version 2.0 using the command above. Earlier builds on the [releases page](https://github.com/Sh7ne/Mac-OpenInVSCode/releases/) predate this arm64-only version.
2. In Finder, move the finished `Open in Code.app` into `/Applications/Utilities`.
3. Open the app once and allow access to Finder when macOS asks, then close the Visual Studio Code window it opens.
4. Hold Command and drag `Open in Code.app` from Utilities to the Finder toolbar.
5. Navigate to a folder and click the toolbar icon to open it in Visual Studio Code.

When replacing an older version, remove its toolbar shortcut and drag the new app into the toolbar.

## Keep the transparent icon

Use `scripts/build.sh` to produce the finished application. It preserves the original
`Monterey.icns` artwork as a custom Finder icon, preventing an extra rounded background
from appearing around the toolbar icon.

Copy the application with Finder or `ditto`. Extract the ZIP with Archive Utility or
`ditto` so that the custom icon's resource fork and Finder metadata are retained:

```sh
ditto -x -k build/Open-in-Code-2.0-arm64.zip build/unpacked
```

If the background returns after a copy that strips metadata, restore the original icon
from the repository root:

```sh
sh scripts/preserve-finder-icon.sh \
  "/Applications/Utilities/Open in Code.app" Monterey.icns
```

## Verify the build

Check that the finished executable contains only arm64:

```sh
lipo -archs "build/Build/Products/Release/Open in Code.app/Contents/MacOS/Open in Code"
```

Expected output: `arm64`.

Check the application signature:

```sh
codesign --verify --verbose=2 "build/Build/Products/Release/Open in Code.app"
```

The build script verifies Xcode's signed intermediate with `codesign --verify --strict`
before applying the custom icon to the finished copy. That intermediate is kept in
`build/DerivedData`. Normal signature verification supports the finished copy;
`--strict` rejects the Finder metadata required by custom icons.

## Credits

Thanks to the original OpenInCode developer, Sertac Ozercan.
`Finder.h` was originally copied from [BetterInfo](https://github.com/davedelong/BetterInfo/blob/master/Finder.h).
The original icon was converted from PNG to ICNS using [Aconvert](https://www.aconvert.com/image/).
