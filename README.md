# Open in Code & Terminal

Two small Finder toolbar apps: open the selected folder, a selected file’s containing
folder, or the current Finder window in Visual Studio Code or Terminal.
If no Finder folder is available, they open the Desktop.

**Version 2.1 requires Apple Silicon (arm64) and macOS 12.1 or later. Intel Macs are not supported.**
Both apps keep transparent toolbar icons. Open in Code requires Visual Studio Code;
Open in Terminal uses the Terminal included with macOS. Neither requires a shell launcher.

## Download and install

1. Download the DMG from the [latest release](https://github.com/Sh7ne/Mac-OpenIn/releases/latest).
   It contains **Open in Code.app** and **Open in Terminal.app**; individual ZIPs are also available.
2. Open the DMG and copy the apps into `/Applications/Utilities` using Finder.
3. Open each app once and allow access to Finder when macOS asks.
4. Command-drag the apps into the Finder toolbar, with Terminal immediately to the left of Code.
5. Navigate to a folder and click either toolbar icon.

If dragging does not work, right-click the toolbar and choose **Text Only**, drag the
apps into place, then switch back to **Icon Only**.
When replacing an older app, remove its toolbar shortcut and drag the new app into place.

These builds are ad hoc signed and are not notarized.

## Build

Install full Xcode, then run:

```sh
git clone https://github.com/Sh7ne/Mac-OpenIn.git
cd Mac-OpenIn
sh scripts/build.sh
```

One Xcode project contains two targets. Both share `main.m`, the minimal `Finder.h`,
`Info.plist`, and `Config.xcconfig`. The only target differences are the destination
application, bundle identifier, name, and icon. The source is Objective-C, so CI uses
Clang static analysis and compiler warnings as errors; SwiftLint does not apply.

The default build produces:

| Output | Location |
| --- | --- |
| Both apps | `build/Build/Products/Release/` |
| DMG with both apps | `build/Open-in-2.1-arm64.dmg` |
| Code ZIP | `build/Open-in-Code-2.1-arm64.zip` |
| Terminal ZIP | `build/Open-in-Terminal-2.1-arm64.zip` |

Use `sh scripts/build.sh Debug` for both Debug builds, or pass `Code` or `Terminal`
as the second argument to build just one app, for example `sh scripts/build.sh Release Code`.
The build verifies arm64 architecture and signatures. CI checks both configurations;
pushing a `v*` tag publishes the checked DMG and ZIPs to GitHub Releases.

## Transparent icons

The build stores the original ICNS artwork as a custom Finder icon, preserving its
transparent background. Copy apps using Finder or `ditto`; extract ZIPs with Archive
Utility or `ditto` so the icon’s resource fork and Finder metadata are retained:

```sh
ditto -x -k build/Open-in-Code-2.1-arm64.zip build/unpacked
```

If another copy tool strips the custom icon, restore it from the repository root:

```sh
sh scripts/preserve-finder-icon.sh \
  "/Applications/Utilities/Open in Code.app" Monterey.icns
sh scripts/preserve-finder-icon.sh \
  "/Applications/Utilities/Open in Terminal.app" Terminal/Terminal.icns
```

Xcode’s signed intermediates are kept in `build/DerivedData` and pass strict signature
verification. Finished apps pass normal `codesign --verify`; `--strict` rejects the
Finder metadata used for custom icons.

## Credits

Original OpenInCode developer: Sertac Ozercan. See [LICENSE](LICENSE).
The minimal Finder declarations derive from the original `Finder.h`, copied from
[BetterInfo](https://github.com/davedelong/BetterInfo/blob/master/Finder.h).
The original Code icon was converted from PNG to ICNS using [Aconvert](https://www.aconvert.com/image/).
