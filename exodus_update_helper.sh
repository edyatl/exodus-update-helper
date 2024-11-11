#!/bin/bash

# Exodus Update Helper Script

# Function to print error message and exit
handle_error() {
    echo "An error occurred during the update process. Exiting."
    exit 1
}

# Exit on any non-zero command and handle errors
set -e
trap 'handle_error' ERR

# Check for required commands
for cmd in unzip wget xdg-open; do
    command -v $cmd >/dev/null 2>&1 || { echo "Error: $cmd is not installed."; exit 1; }
done

# Step 1: Get current version of Exodus
CURRENT_EXODUS_PATH=$HOME/Exodus-linux-x64/Exodus
CURRENT_VERSION=$($CURRENT_EXODUS_PATH --version 2>/dev/null) || { echo "Error: Unable to get current Exodus version."; exit 1; }
echo "Current Exodus version: $CURRENT_VERSION"

# Step 2: Get last available stable Exodus version and hashes URL
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36"
HASHES_URL=$(wget --https-only -qO- --header="User-Agent: $USER_AGENT" https://www.exodus.com/download/ | grep -oP '<a[^>]+href="\K[^"]*hashes-exodus-[0-9]+\.[0-9]+\.[0-9]+\.txt') || { echo "Error: Unable to retrieve hashes file URL."; exit 1; }

LAST_VERSION=$(echo $HASHES_URL | grep -oE '[0-9]+\.[0-9]+\.[0-9]+') || { echo "Error: Unable to extract last version."; exit 1; }
echo "Last available Exodus version: $LAST_VERSION"

# Step 3: Compare current and last versions
if [[ "$CURRENT_VERSION" == "$LAST_VERSION" ]]; then
    echo "Exodus is already up to date."
    exit 0
fi

echo "Updating to latest version: $LAST_VERSION"

# Step 4: Download Exodus binary archive and hashes file
DOWNLOAD_DIR=$(xdg-user-dir DOWNLOAD 2>/dev/null) || { echo "Error: Unable to determine downloads directory."; exit 1; }
BINARY_URL="https://downloads.exodus.com/releases/exodus-linux-x64-$LAST_VERSION.zip"

BINARY_ARCHIVE="$DOWNLOAD_DIR/exodus-linux-x64-$LAST_VERSION.zip"
HASHES_FILE="$DOWNLOAD_DIR/$(basename $HASHES_URL)"

# Check if binary archive already exists
if [[ -f "$BINARY_ARCHIVE" ]]; then
    echo "Binary archive already exists. Skipping download."
else
    # Download binary archive
    wget --https-only --header="User-Agent: $USER_AGENT" -O "$BINARY_ARCHIVE" "$BINARY_URL" || { echo "Error: Unable to download Exodus binary archive."; exit 1; }
fi

# Download hashes file
wget --https-only --header="User-Agent: $USER_AGENT" -O "$HASHES_FILE" "$HASHES_URL" || { echo "Error: Unable to download hashes file."; exit 1; }

# Step 5: Verify hash of downloaded binary
cd "$DOWNLOAD_DIR" || { echo "Error: Unable to change to downloads directory."; exit 1; }
sha256sum -c "$(basename $HASHES_URL)" --ignore-missing || { echo "Error: Hash verification failed."; exit 1; }

# Step 6: Unpack archive to current Exodus directory with overwrite
EXODUS_PATH=$HOME
unzip -o "exodus-linux-x64-$LAST_VERSION.zip" -d "$EXODUS_PATH" || { echo "Error: Unable to unzip Exodus archive."; exit 1; }

# Step 7: Verify update was successful
UPDATED_VERSION=$($CURRENT_EXODUS_PATH --version 2>/dev/null) || { echo "Error: Unable to get updated Exodus version."; exit 1; }
if [[ "$UPDATED_VERSION" == "$LAST_VERSION" ]]; then
    echo "Exodus successfully updated to version $LAST_VERSION."
else
    echo "Error: Update failed. Current version is still $UPDATED_VERSION."
    exit 1
fi

