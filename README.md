# Exodus Update Helper

`exodus_update_helper.sh` is a Bash script that automates the process of updating the Exodus cryptocurrency wallet on Linux. The script checks the current installed version, downloads the latest stable release if needed, verifies its hash, extracts the new version, and verifies the update, all while ensuring dependencies are installed.

## Requirements
- **Exodus Wallet** installed in `~/Exodus-linux-x64/`.
- The following command-line tools:
  - `wget`
  - `unzip`
  - `xdg-user-dir`
- Internet connection for downloading updates.

## Installation
1. Clone this repository or download the `exodus_update_helper.sh` file.
2. Make the script executable:
   ```bash
   chmod +x exodus_update_helper.sh
   ```
3. Run the script from the current directory.

## Script Workflow
The `exodus_update_helper.sh` script performs the following steps:
1. **Dependency Check**: Verifies that `wget`, `unzip`, and `xdg-user-dir` are installed. If any are missing, the script exits with an error.
2. **Current Version Check**: Retrieves the current Exodus version from the installation in `~/Exodus-linux-x64/Exodus`.
3. **Latest Version Retrieval**: Fetches the latest stable version and the corresponding hash file URL from the Exodus download page.
4. **Version Comparison**: Compares the current and latest versions. If they are the same, the script exits without updating.
5. **Download Process**: Downloads the latest binary and hash file to the default downloads directory. Skips downloading if files are already present.
6. **Hash Verification**: Verifies the integrity of the downloaded binary using the hash file.
7. **Update Installation**: Extracts the binary files to the existing `~/Exodus-linux-x64/` directory.
8. **Update Verification**: Checks that the installed version matches the latest version, confirming a successful update.

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

