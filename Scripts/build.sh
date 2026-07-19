#!/bin/bash

# 1. Cleanup
pkill DinoClip || true
rm -rf DinoClip.app DinoClip.dmg

# 2. Compile
swiftc -O main.swift -o DinoClip -framework SwiftUI -framework AppKit

# 3. Structure
mkdir -p DinoClip.app/Contents/MacOS
mkdir -p DinoClip.app/Contents/Resources

# 4. Move Binary & Icon
mv DinoClip DinoClip.app/Contents/MacOS/
cp Resources/icon.icns DinoClip.app/Contents/Resources/AppIcon.icns

# 5. Updated Info.plist (Telling macOS about the icon)
cat <<EOF > DinoClip.app/Contents/Info.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>DinoClip</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon.icns</string>
    <key>CFBundleIdentifier</key>
    <string>com.dinoclip.app</string>
    <key>CFBundleName</key>
    <string>DinoClip</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

# 6. Create the DMG with a Volume Icon
mkdir -p dist
cp -R DinoClip.app dist/
ln -s /Applications dist/Applications

# This makes the "Disk" icon look like your Dino when mounted
cp Resources/icon.icns dist/.VolumeIcon.icns
python3 -c "import Foundation; Foundation.NSWorkspace.sharedWorkspace().setIcon_forFile_options_(Foundation.NSImage.alloc().initWithContentsOfFile_('Resources/icon.icns'), 'dist', 0)"

hdiutil create -volname "DinoClip" -srcfolder dist -ov -format UDZO DinoClip.dmg
rm -rf dist

echo "✅ DinoClip v1.0 is ready with Pro Icons!"