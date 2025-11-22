#!/bin/bash

# Bulk Install Script
# Purpose: Make bulk package installation easier with customizable install commands and package lists
# Supports progress tracking, logging, dry-run, resume, and non-interactive modes

# Configuration Section - Customize these variables
INSTALL_COMMAND="sudo pacman -S"  # Default install command (can be changed)
PACKAGES_FILE=""  # Package file to read from (auto-detected if empty)
LOG_FILE=""       # Log file for operations (optional)
VERBOSE=false     # Verbose output
DRY_RUN=false     # Dry run mode (simulate without installing)
RESUME_ON_FAIL=true  # Continue with next package if one fails
NON_INTERACTIVE=false # Skip confirmations and prompts
FORCE=false       # Force install even if confirmation skipped
# Function to auto-detect package manager
detect_package_manager() {
    if command -v apt &>/dev/null; then
        echo "sudo apt install {pkg}"
    elif command -v dnf &>/dev/null; then
        echo "sudo dnf install {pkg}"
    elif command -v pacman &>/dev/null; then
        echo "sudo pacman -S {pkg}"
    elif command -v zypper &>/dev/null; then
        echo "sudo zypper install {pkg}"
    elif command -v apk &>/dev/null; then
        echo "sudo apk add {pkg}"
    else
        echo "sudo pacman -S {pkg}"  # fallback
    fi
}

# Default package list
PACKAGES=(
    "firefox"
    "vim"
    "nano"
    "curl"
    "wget"
    "git"
    "htop"
    "neofetch"
    "tree"
    "unzip"
    "zip"
    "tar"
    "gzip"
    "tmux"
    "ranger"
    "feh"
    "mpv"
    "p7zip"
    "rsync"
    "bash-completion"
)

# Set default command if not overridden
if [[ "$INSTALL_COMMAND" == "sudo pacman -S" ]]; then
    INSTALL_COMMAND=$(detect_package_manager)
fi

# Function to load packages from file or use defaults
load_packages() {
    local pkg_file="$1"

    # If no file specified, try to auto-detect
    if [ -z "$pkg_file" ]; then
        for file in "packages" "packages.txt" "pkgs.txt" "pkgs"; do
            if [ -f "$file" ]; then
                pkg_file="$file"
                break
            fi
        done
    fi

    # Load from file if found (source it as a bash script)
    if [ -n "$pkg_file" ] && [ -f "$pkg_file" ]; then
        source "$pkg_file"
        echo "Sourced packages from: $pkg_file"
        echo "Packages: ${#PACKAGES[@]}"
        if [ -n "$SHELL_COMMANDS" ]; then
            echo "Shell commands: ${#SHELL_COMMANDS[@]}"
        fi
        if [ -n "$INSTALL_COMMAND" ] && [ "$INSTALL_COMMAND" != "sudo pacman -S" ]; then
            echo "Using custom install command from file: $INSTALL_COMMAND"
        fi
    else
        echo "Using default package list"
    fi
}

# Function to display usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -c, --command CMD      Set custom install command (use {pkgs} for bulk install)"
    echo "  -p, --packages-file     Specify custom package list file"
    echo "  -l, --list             Show the list of packages to be installed (dry-run)"
    echo "  -d, --dry-run          Simulate installation without actually installing"
    echo "  -v, --verbose          Enable verbose output"
    echo "  -q, --quiet            Non-interactive mode (skip confirmations)"
    echo "  --no-resume            Exit on first failure (default: continue)"
    echo "  --log FILE             Log operations to specified file"
    echo "  --force                Force installation (implies --quiet)"
    echo "  -h, --help             Show this help message"
    echo
    echo "Examples:"
    echo "  $0                     # Install all packages with default command"
    echo "  $0 -c 'sudo apt install {pkgs}'  # Bulk install with apt"
    echo "  $0 -p custom-pkgs.txt  # Use custom package file"
    echo "  $0 --list              # Show packages that will be installed"
    echo "  $0 --dry-run           # Simulate installation"
    echo "  $0 --quiet --log install.log  # Install quietly and log"
}

# Function to display package list
show_package_list() {
    if [[ ${#SHELL_COMMANDS[@]} -gt 0 ]]; then
        echo "Shell commands to execute:"
        for cmd in "${SHELL_COMMANDS[@]}"; do
            echo "  - $cmd"
        done
        echo
    fi
    echo "Packages to be installed:"
    for pkg in "${PACKAGES[@]}"; do
        echo "  - $pkg"
    done
    echo
    echo "Install command: $INSTALL_COMMAND"
    if [[ "$INSTALL_COMMAND" == *"{pkgs}"* ]]; then
        echo "Mode: Bulk installation (packages joined with command)"
    else
        echo "Mode: Individual installation (one package at a time)"
    fi
}

# Function to log messages
log() {
    local level="$1"
    local msg="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Always print to stdout/stderr for user feedback
    if [[ "$level" == "ERROR" ]]; then
        echo "✗ $msg" >&2
    elif [[ "$level" == "SUCCESS" ]]; then
        echo "✓ $msg"
    elif [[ "$level" == "INFO" ]]; then
        echo "ℹ $msg"
    else
        echo "$msg"
    fi

    # Log to file if specified
    if [ -n "$LOG_FILE" ]; then
        echo "$timestamp [$level] $msg" >> "$LOG_FILE"
    fi
}

# Function to start timing
start_timer() {
    START_TIME=$(date +%s)
}

# Function to get elapsed time
get_elapsed_time() {
    local end_time=$(date +%s)
    local elapsed=$((end_time - START_TIME))
    echo "$elapsed"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--command)
            INSTALL_COMMAND="$2"
            shift 2
            ;;
        -p|--packages-file)
            PACKAGES_FILE="$2"
            shift 2
            ;;
        -l|--list)
            DRY_RUN=true
            load_packages "$PACKAGES_FILE"
            show_package_list
            exit 0
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -q|--quiet)
            NON_INTERACTIVE=true
            shift
            ;;
        --no-resume)
            RESUME_ON_FAIL=false
            shift
            ;;
        --log)
            LOG_FILE="$2"
            shift 2
            ;;
        --force)
            FORCE=true
            NON_INTERACTIVE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main installation function
install_packages() {
    local total_pkgs=${#PACKAGES[@]}
    local installed_count=0
    local failed_count=0
    local start_time

    # Load packages
    load_packages "$PACKAGES_FILE"

    log "INFO" "=== Bulk Install Script ==="
    if [ "$VERBOSE" = true ] || [ "$DRY_RUN" = true ]; then
        echo
        echo "Install command: $INSTALL_COMMAND"
        echo "Number of packages: $total_pkgs"
        echo "Number of shell commands: ${#SHELL_COMMANDS[@]}"
        echo "Resume on fail: $RESUME_ON_FAIL"
        if [ -n "$LOG_FILE" ]; then
            echo "Logging to: $LOG_FILE"
        fi
        echo
        show_package_list
    fi

    # Skip confirmation in non-interactive mode or dry-run
    if [ "$NON_INTERACTIVE" = false ] && [ "$DRY_RUN" = false ]; then
        echo
        read -p "Do you want to proceed with installation? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "INFO" "Installation cancelled by user"
            exit 0
        fi
    fi

    if [ "$DRY_RUN" = true ]; then
        echo "Dry run mode: Simulating installation"
    fi

    log "INFO" "Starting installation"
    start_timer

    # Execute custom shell commands first (if any)
    if [[ ${#SHELL_COMMANDS[@]} -gt 0 ]]; then
        log "INFO" "Executing shell commands"
        for cmd in "${SHELL_COMMANDS[@]}"; do
            echo "Running: $cmd"
            if ([ "$DRY_RUN" = false ] && $cmd) || [ "$DRY_RUN" = true ]; then
                if [ "$DRY_RUN" = false ]; then
                    log "SUCCESS" "Shell command completed"
                else
                    log "INFO" "[DRY RUN] Shell command would be executed"
                fi
            else
                log "ERROR" "Shell command failed: $cmd"
                if [ "$RESUME_ON_FAIL" = false ]; then
                    log "INFO" "Exiting due to shell command error"
                    exit 1
                fi
            fi
        done
    fi

    # Check if bulk install with {pkgs} placeholder
    if [[ "$INSTALL_COMMAND" == *"{pkgs}"* ]]; then
        # Bulk install: replace {pkgs} with space-separated package list
        pkg_list="${PACKAGES[*]}"
        cmd="${INSTALL_COMMAND//\{pkgs\}/$pkg_list}"
        log "INFO" "Bulk installation mode"
        echo "Executing: $cmd"
        if ([ "$DRY_RUN" = false ] && $cmd) || [ "$DRY_RUN" = true ]; then
            installed_count=$total_pkgs
            if [ "$DRY_RUN" = false ]; then
                log "SUCCESS" "Bulk installation completed successfully"
            else
                log "INFO" "[DRY RUN] Bulk installation would be executed"
            fi
            log "INFO" "Installed $installed_count packages"
        else
            log "ERROR" "Bulk installation failed"
            failed_count=$total_pkgs
            exit 1
        fi
    else
        # Individual installs
        log "INFO" "Individual installation mode"
        for i in "${!PACKAGES[@]}"; do
            pkg="${PACKAGES[$i]}"
            echo "[$((i+1))/$total_pkgs] Installing $pkg..."
            if ([ "$DRY_RUN" = false ] && $INSTALL_COMMAND "$pkg") || [ "$DRY_RUN" = true ]; then
                if [ "$DRY_RUN" = false ]; then
                    log "SUCCESS" "Successfully installed $pkg"
                else
                    log "INFO" "[DRY RUN] Would install $pkg"
                fi
                ((installed_count++))
            else
                log "ERROR" "Failed to install $pkg"
                ((failed_count++))
                if [ "$RESUME_ON_FAIL" = false ]; then
                    log "INFO" "Exiting due to installation error"
                    exit 1
                fi
            fi
        done
    fi

    elapsed=$(get_elapsed_time)
    log "INFO" "Installation complete. Installed: $installed_count, Failed: $failed_count, Time: ${elapsed}s"
}

# Run the main function
install_packages
