#!/bin/bash

# Exodus Update Helper Script

####################
# Global variables #
####################
readonly USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36"
readonly REQUIRED_COMMANDS=(unzip wget xdg-open)

###################
# Error handling  #
###################
set -e

handle_error() {
    local error_message="$1"
    echo "Error: ${error_message:-'An error occurred during the update process.'}" >&2
    exit 1
}

trap 'handle_error' ERR

####################
# Helper functions #
####################
check_dependencies() {
    local missing_commands=()
    
    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [ ${#missing_commands[@]} -ne 0 ]; then
        handle_error "Required commands not installed: ${missing_commands[*]}"
    fi
}

get_current_version() {
    local exodus_path="$HOME/Exodus-linux-x64/Exodus"
    "$exodus_path" --version 2>/dev/null || handle_error "Unable to get current Exodus version"
}

fetch_latest_version_info() {
    local download_page_url="https://www.exodus.com/download/"
    local hashes_url
    
    hashes_url=$(wget --https-only -qO- --header="User-Agent: $USER_AGENT" "$download_page_url" | 
                 grep -oP '<a[^>]+href="\K[^"]*hashes-exodus-[0-9]+\.[0-9]+\.[0-9]+\.txt') || 
        handle_error "Unable to retrieve hashes file URL"
    
    echo "$hashes_url"
}

extract_version_number() {
    local url="$1"
    echo "$url" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || 
        handle_error "Unable to extract version number"
}

download_file() {
    local url="$1"
    local output_path="$2"
    local skip_if_exists="${3:-false}"
    
    if [[ "$skip_if_exists" == "true" ]] && [[ -f "$output_path" ]]; then
        echo "File already exists: $output_path"
        return 0
    fi
    
    wget --https-only --header="User-Agent: $USER_AGENT" -O "$output_path" "$url" || 
        handle_error "Unable to download: $url"
}

verify_hash() {
    local download_dir="$1"
    local hashes_file="$2"
    
    cd "$download_dir" || handle_error "Unable to change to downloads directory"
    sha256sum -c "$hashes_file" --ignore-missing || 
        handle_error "Hash verification failed"
}

unpack_archive() {
    local archive_path="$1"
    local target_dir="$2"
    
    unzip -o "$archive_path" -d "$target_dir" || 
        handle_error "Unable to unzip archive: $archive_path"
}

verify_update() {
    local current_version="$1"
    local expected_version="$2"
    
    if [[ "$current_version" != "$expected_version" ]]; then
        handle_error "Update failed. Current version is still $current_version"
    fi
}

###################
# Main function   #
###################
main() {
    # Check dependencies
    check_dependencies
    
    # Get current version
    local current_version
    current_version=$(get_current_version)
    echo "Current Exodus version: $current_version"
    
    # Get latest version info
    local hashes_url
    hashes_url=$(fetch_latest_version_info)
    local last_version
    last_version=$(extract_version_number "$hashes_url")
    echo "Last available Exodus version: $last_version"
    
    # Check if update is needed
    if [[ "$current_version" == "$last_version" ]]; then
        echo "Exodus is already up to date."
        exit 0
    fi
    
    echo "Updating to latest version: $last_version"
    
    # Setup download paths
    local download_dir
    download_dir=$(xdg-user-dir DOWNLOAD) || handle_error "Unable to determine downloads directory"
    local binary_url="https://downloads.exodus.com/releases/exodus-linux-x64-$last_version.zip"
    local binary_archive="$download_dir/exodus-linux-x64-$last_version.zip"
    local hashes_file="$download_dir/$(basename "$hashes_url")"
    
    # Download files
    download_file "$binary_url" "$binary_archive" "true"
    download_file "$hashes_url" "$hashes_file"
    
    # Verify hash
    verify_hash "$download_dir" "$(basename "$hashes_url")"
    
    # Unpack archive
    unpack_archive "$binary_archive" "$HOME"
    
    # Verify update
    local updated_version
    updated_version=$(get_current_version)
    verify_update "$updated_version" "$last_version"
    
    echo "Exodus successfully updated to version $last_version."
}

# Execute main function
main "$@"
