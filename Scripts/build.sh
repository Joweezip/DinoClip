#!/bin/bash

# 1. Kill old app
pkill DinoClip || true

# 2. Compile
swiftc -O main.swift -o DinoClip -framework SwiftUI -framework AppKit

# 3. Clean and Create Structure
rm -rf DinoClip.app
mkdir -p DinoClip.app/Contents/MacOS
mkdir -p DinoClip.app/Contents/Resources

# 4. Move Binary
mv DinoClip DinoClip.app/Contents/MacOS/

# 5. ICON FIX: Look for Icon.png or icon.png and force it to be icon.png in resources
if [ -f "Icon.png" ]; then
    cp Icon.png DinoClip.app/Contents/Resources/icon.png
elif [ -f "icon.png" ]; then
    cp icon.png DinoClip.app/Contents/Resources/icon.png
fi

# 6. Create Info.plist
cat <<EOF > DinoClip.app/Contents/Info.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>DinoClip</string>
    <key>CFBundleIdentifier</key>
    <string>com.dinoclip.app</string>
    <key>CFBundleName</key>
    <string>DinoClip</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

# 7. Create DMG
mkdir -p dist
cp -R DinoClip.app dist/
hdiutil create -volname "DinoClip" -srcfolder dist -ov -format UDZO DinoClip.dmg
rm -rf dist

# 8. Open
open DinoClip.app
echo "✅ DinoClip is now built with the internal icon!"