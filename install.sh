#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHAT_SCRIPT="$SCRIPT_DIR/chat"
CHAT_HTML="$SCRIPT_DIR/chat.html"
DESKTOP_DIR="$HOME/.local/share/applications"
DESKTOP_FILE="$DESKTOP_DIR/streamerbot-chat.desktop"

echo "StreamerBot Chat — Installer"
echo "=============================="

# Ensure the chat script exists
if [[ ! -f "$CHAT_SCRIPT" ]]; then
    echo "Error: chat script not found at $CHAT_SCRIPT"
    exit 1
fi

# Ensure the chat HTML exists
if [[ ! -f "$CHAT_HTML" ]]; then
    echo "Error: chat HTML not found at $CHAT_HTML"
    exit 1
fi

# Ensure chat script is executable
chmod +x "$CHAT_SCRIPT"
echo "✓ Made chat script executable"

# Ensure desktop applications directory exists
mkdir -p "$DESKTOP_DIR"

# Write the .desktop file
cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=StreamerBot Chat
Comment=Live chat overlay via Streamer.bot
Exec=xdg-open file://$CHAT_HTML
Icon=web-browser
Terminal=false
Type=Application
Categories=Network;
EOF

echo "✓ Installed desktop entry to $DESKTOP_FILE"

# Notify the desktop environment of the new entry
if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "$DESKTOP_DIR" 2>/dev/null
    echo "✓ Updated desktop database"
fi

echo ""
echo "Done! You can now launch 'StreamerBot Chat' from your application launcher."
echo "Or run it directly: $CHAT_SCRIPT"
