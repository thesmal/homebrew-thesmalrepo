# Bulk Install Script

A Bash script to simplify bulk package installation across different Linux distributions with customizable install commands and package lists.

## Features

- **Auto-detection**: Automatically detects the package manager and sets appropriate install commands.
- **Custom Package Lists**: Use external files to define packages using standard Bash syntax.
- **Flexible Install Modes**: Supports both individual package installation and bulk installation.
- **Custom Commands**: Define custom install commands or execute shell commands before package installation.
- **Cross-Platform**: Works with apt, dnf, pacman, zypper, and apk.

## Quick Start

1. Make the script executable:
   ```bash
   chmod +x bulkinstall.sh
   ```

2. Run the script with default settings:
   ```bash
   ./bulkinstall.sh
   ```

## Usage

```bash
./bulkinstall.sh [OPTIONS]
```

### Options

- `-c, --command CMD`: Set a custom install command. Use `{pkg}` for individual installs or `{pkgs}` for bulk installs.
- `-p, --packages-file FILE`: Specify a custom package list file.
- `-l, --list`: Show the list of packages to be installed (dry-run mode).
- `-d, --dry-run`: Simulate installation without actually installing packages.
- `-v, --verbose`: Enable verbose output with additional information.
- `-q, --quiet`: Non-interactive mode (skip confirmations).
- `--no-resume`: Exit on first failure instead of continuing (default: continue).
- `--log FILE`: Log all operations to the specified file.
- `--force`: Force installation (implies `--quiet`).
- `-h, --help`: Show help message.

### Examples

- Install with default settings:
  ```bash
  ./bulkinstall.sh
  ```

- Install packages using apt for bulk installation:
  ```bash
  ./bulkinstall.sh -c 'sudo apt install {pkgs}'
  ```

- Use a custom package file:
  ```bash
  ./bulkinstall.sh -p custom-packages.sh
  ```

- Show what will be installed:
  ```bash
  ./bulkinstall.sh --list
  ```

## Package File Syntax

The package file is a Bash script that defines arrays and variables. The script sources this file directly.

### Basic Syntax

```bash
PACKAGES=(
    "firefox"
    "vim"
    "nano"
    "curl"
    "wget"
    "git"
)

SHELL_COMMANDS=(
    "echo 'Hello from shell command'"
    "mkdir -p ~/.config"
)

INSTALL_COMMAND="sudo pacman -S {pkg}"
```

### Variables

- `PACKAGES`: Array of package names to install.
- `SHELL_COMMANDS` (optional): Array of shell commands to execute before installing packages.
- `INSTALL_COMMAND` (optional): Custom install command. Overrides the auto-detected command.

### Advanced Usage

You can include conditionals, functions, or any valid Bash code in the package file:

```bash
if command -v nvidia-smi >/dev/null; then
    PACKAGES+=("nvidia-prime")
fi

PACKAGES=(
    "firefox"
    "vim"
)

SHELL_COMMANDS=(
    "git clone https://github.com/user/repo ~/.repo"
)
```

## Auto-Detection

The package list file is auto-detected in this order:
1. `packages`
2. `packages.txt`
3. `pkgs.txt`
4. `pkgs`

Use the `-p` option to specify a custom file.

## Default Package List

If no package file is found, the script uses a built-in list of common packages:
- firefox, vim, nano, curl, wget, git, htop, neofetch, tree, unzip, zip, tar, gzip, tmux, ranger, feh, mpv, p7zip, rsync, bash-completion

## Install Modes

### Individual Installation
Default mode. Installs each package one by one.
- Command: `sudo pacman -S firefox`, `sudo pacman -S vim`, etc.

### Bulk Installation
Use `{pkgs}` in the install command for bulk installs.
- Command: `sudo apt install {pkgs}` → `sudo apt install firefox vim nano ...`

## Configuration

Edit the top of `bulkinstall.sh` to customize defaults:
- `INSTALL_COMMAND`: Default install command (auto-detected based on package manager).
- `PACKAGES_FILE`: Default package file path.

## Requirements

- Bash
- Curl (for package manager detection if needed)
- Access to package manager commands (sudo)

## License

MIT License
