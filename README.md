# Open in Code & Terminal

Open the current Finder folder in Visual Studio Code or Terminal with one click from the Finder toolbar.

**Both applications require Apple Silicon (arm64) and macOS 12.1 or later. Intel Macs are not supported.**

- **Open in Code.app** (2.0) opens folders in Visual Studio Code and keeps the original transparent icon.
- **Open in Terminal.app** (1.0) opens a Terminal window at the selected folder, with a transparent `>_` icon.

## How it works

- Select a folder to open that folder in the application you choose.
- Select a file to open its containing folder.
- With nothing selected, open the folder shown in the front Finder window.

Open in Code requires Visual Studio Code to be installed; its `code` command-line launcher is not required.
Open in Terminal uses the Terminal application included with macOS. It passes directory paths directly to
Terminal, so spaces, quotes, and other shell characters in folder names are handled as filenames.
If no Finder folder is available, Open in Terminal opens the Desktop folder.

## Build from source

Install full Xcode with a macOS SDK that supports arm64. Run these commands to clone and build:

```sh
git clone https://github.com/Sh7ne/Mac-OpenInVSCode.git
cd Mac-OpenInVSCode
sh scripts/build.sh
sh scripts/build.sh Release Terminal
```

| Output | Location |
| --- | --- |
| Open in Code | `build/Build/Products/Release/Open in Code.app` |
| Code ZIP package | `build/Open-in-Code-2.0-arm64.zip` |
| Open in Terminal | `build/Build/Products/Release/Open in Terminal.app` |
| Terminal ZIP package | `build/Open-in-Terminal-1.0-arm64.zip` |

For Debug builds, run `sh scripts/build.sh Debug` or `sh scripts/build.sh Debug Terminal`. Applications are generated in
`build/Build/Products/Debug`.

Both configurations build only arm64, and the source rejects non-arm64 compilation.
The application uses an ad hoc signature for local use and is not notarized.

## Installation and usage

1. Build the applications using the commands above. Earlier builds on the [releases page](https://github.com/Sh7ne/Mac-OpenInVSCode/releases/) predate these versions.
2. In Finder, move the finished applications into `/Applications/Utilities`.
3. Open each app once and allow access to Finder when macOS asks, then close the window it opens.
4. Hold Command and drag `Open in Code.app` from Utilities to the Finder toolbar.
5. Hold Command and drag `Open in Terminal.app` into the toolbar, immediately to the left of Open in Code.
6. Navigate to a folder and click the appropriate toolbar icon to open it in Code or Terminal.

If dragging does not work on your macOS version, right-click the Finder toolbar and
choose **Text Only**, then drag the app into place. Switch back to **Icon Only** afterward.

When replacing an older version, remove its toolbar shortcut and drag the new app into the toolbar.

## Keep the transparent icon

Use `scripts/build.sh` to produce the finished applications. It preserves `Monterey.icns`
for Code and `Terminal/Terminal.icns` for Terminal as custom Finder icons, preventing an
extra rounded background from appearing around the toolbar icons.

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
sh scripts/preserve-finder-icon.sh \
  "/Applications/Utilities/Open in Terminal.app" Terminal/Terminal.icns
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
