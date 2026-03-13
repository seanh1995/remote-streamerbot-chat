#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHAT_HTML="$SCRIPT_DIR/chat.html"
DESKTOP_DIR="$HOME/.local/share/applications"
DESKTOP_FILE="$DESKTOP_DIR/streamerbot-chat.desktop"

desktop_entry_path() {
    local desktop_id="$1"

    for base_dir in "$HOME/.local/share/applications" "/usr/local/share/applications" "/usr/share/applications"; do
        if [[ -f "$base_dir/$desktop_id" ]]; then
            printf '%s\n' "$base_dir/$desktop_id"
            return 0
        fi
    done

    return 1
}

desktop_entry_looks_like_browser() {
    local desktop_id="$1"
    local desktop_path

    desktop_path="$(desktop_entry_path "$desktop_id")" || return 1

    grep -Eiq '^(Categories=.*WebBrowser|MimeType=.*(x-scheme-handler/(http|https)|text/html|application/xhtml\+xml))' "$desktop_path"
}

is_supported_browser() {
    local desktop_id="$1"

    case "$desktop_id" in
        *.firefox.desktop|com.google.Chrome.desktop|google-chrome.desktop|google-chrome-stable.desktop|chromium.desktop|chromium-browser.desktop|brave-browser.desktop|brave-browser-stable.desktop|vivaldi-stable.desktop|org.gnome.Epiphany.desktop|epiphany.desktop|org.kde.falkon.desktop|librewolf.desktop)
            return 0
            ;;
    esac

    desktop_entry_looks_like_browser "$desktop_id"
}

find_fallback_browser() {
    local candidate

    for candidate in \
        firefox.desktop \
        org.mozilla.firefox.desktop \
        com.google.Chrome.desktop \
        google-chrome.desktop \
        google-chrome-stable.desktop \
        chromium.desktop \
        chromium-browser.desktop \
        brave-browser.desktop \
        brave-browser-stable.desktop \
        vivaldi-stable.desktop \
        org.gnome.Epiphany.desktop \
        epiphany.desktop \
        org.kde.falkon.desktop \
        librewolf.desktop
    do
        if desktop_entry_path "$candidate" &>/dev/null && is_supported_browser "$candidate"; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    return 1
}

echo "StreamerBot Chat — Installer"
echo "=============================="

# Ensure the chat HTML exists
if [[ ! -f "$CHAT_HTML" ]]; then
    echo "Error: chat HTML not found at $CHAT_HTML"
    exit 1
fi

# Ensure required desktop utilities are available
if ! command -v xdg-open &>/dev/null; then
    echo "Error: xdg-open is not installed or not in PATH"
    exit 1
fi

# Ensure desktop applications directory exists
mkdir -p "$DESKTOP_DIR"

CURRENT_DEFAULT_BROWSER="$(xdg-settings get default-web-browser 2>/dev/null || true)"
HTML_HANDLER="$(xdg-mime query default text/html 2>/dev/null || true)"

if is_supported_browser "$CURRENT_DEFAULT_BROWSER"; then
    TARGET_BROWSER="$CURRENT_DEFAULT_BROWSER"
elif is_supported_browser "$HTML_HANDLER"; then
    TARGET_BROWSER="$HTML_HANDLER"
else
    TARGET_BROWSER="$(find_fallback_browser || true)"
fi

if [[ -z "$TARGET_BROWSER" ]]; then
    echo "Error: could not find a supported native browser (Firefox, Chrome/Chromium, or another WebBrowser desktop entry)."
    exit 1
fi

if [[ "$CURRENT_DEFAULT_BROWSER" != "$TARGET_BROWSER" ]]; then
    echo "! Default browser was '$CURRENT_DEFAULT_BROWSER'; switching to '$TARGET_BROWSER'"
fi

if [[ "$HTML_HANDLER" != "$TARGET_BROWSER" ]]; then
    echo "! HTML handler was '$HTML_HANDLER'; switching to '$TARGET_BROWSER'"
fi

xdg-mime default "$TARGET_BROWSER" text/html application/xhtml+xml x-scheme-handler/http x-scheme-handler/https

if command -v xdg-settings &>/dev/null; then
    xdg-settings set default-web-browser "$TARGET_BROWSER" >/dev/null 2>&1 || true
fi

echo "✓ Browser associations set to $TARGET_BROWSER"

# Write the .desktop file
cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=StreamerBot Chat
Comment=Live chat overlay via Streamer.bot
TryExec=xdg-open
Exec=xdg-open "$CHAT_HTML"
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
echo "Or run it directly: xdg-open $CHAT_HTML"
