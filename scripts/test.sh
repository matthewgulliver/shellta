#!/bin/bash
# Shell Script Template Generator with Safety Features
generate_script() {
    # Environment constants
    local REPOS_DIR="$HOME/Repos"
    local SCRIPTS_DIR="$HOME/Scripts" 
    local LOCAL_BIN="$HOME/.local/bin"
    local BASHRC_PATH="$HOME/.bashrc"
    
    # Initialize variables
    local script_name=""
    local script_description=""
    local author="${USER}"
    local dry_run=false
    local output_file=""
    local temp_file=""
    
    # Enhanced clipboard function - fixed SC2120/SC2119[2]
    cb() {
        local input=""
        if ! command -v xclip > /dev/null 2>&1; then
            echo "Warning: xclip not installed. Cannot copy to clipboard." >&2
            return 1
        fi
        
        # Handle both piped input and arguments
        if [[ $# -gt 0 ]]; then
            # Arguments provided
            input="$*"
        elif [[ ! -t 0 ]]; then
            # Input from stdin/pipe
            input="$(cat)"
        else
            echo "Usage: cb <string> or echo <string> | cb" >&2
            return 1
        fi
        
        if [[ -z "$input" ]]; then
            echo "No input provided" >&2
            return 1
        fi
        
        echo -n "$input" | xclip -selection c
        if [[ ${#input} -gt 80 ]]; then 
            input="$(echo "$input" | cut -c1-80)..."
        fi
        echo "Copied to clipboard: $input" >&2
    }
    
    # Input validation function
    validate_input() {
        local input="$1"
        local clean_input="${input//[^a-zA-Z0-9_-]/}"
        echo "$clean_input"
    }
    
    # Confirmation prompt
    confirm_action() {
        local prompt="$1"
        read -p "$prompt (y/N): " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]]
    }
    
    # Error handling function - used in trap
    handle_error() {
        echo "Error on line $1: Command failed" >&2
        exit 1
    }
    
    # Get file permissions safely - fixed SC2012[4][5]
    get_file_permissions() {
        local file="$1"
        if [[ -f "$file" ]]; then
            stat -c "%A" "$file" 2>/dev/null || ls -la "$file" | cut -d' ' -f1
        fi
    }
    
    # Parse parameters
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--name)
                script_name="$(validate_input "$2")"
                shift 2
                ;;
            -d|--description)
                script_description="$2"
                shift 2
                ;;
            -a|--author)
                author="$2"
                shift 2
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            -o|--output)
                output_file="$2"
                shift 2
                ;;
            -h|--help)
                cat << 'EOF'
Usage: generate_script [OPTIONS]

Options:
    -n, --name NAME           Script name (required)
    -d, --description DESC    Script description
    -a, --author AUTHOR       Author name (default: current user)
    --dry-run                 Show what would be generated without creating
    -o, --output FILE         Output file path
    -h, --help               Show this help

Example:
    generate_script -n "backup_tool" -d "System backup utility" --dry-run
EOF
                return 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done
    
    # Validate required parameters
    if [[ -z "$script_name" ]]; then
        echo "Error: Script name is required. Use -n or --name option." >&2
        return 1
    fi
    
    # Set output file if not specified
    if [[ -z "$output_file" ]]; then
        output_file="$SCRIPTS_DIR/${script_name}.sh"
    fi
    
    # Create temporary file for generation
    temp_file=$(mktemp)
    # Fixed SC2064 - use single quotes for trap[3]
    trap 'rm -f "$temp_file"' EXIT
    trap 'handle_error $LINENO' ERR
    
    # Generate script template using heredoc
    cat > "$temp_file" << EOF
#!/bin/bash
#
# Script: ${script_name}.sh
# Description: ${script_description:-"Generated script template"}
# Author: ${author}
# Created: $(date '+%Y-%m-%d %H:%M:%S')
# Version: 1.0.0
#
# Environment: $(uname -s) $(uname -r)
# Bash Version: \${BASH_VERSION}
#

# Safety settings - strict error handling[1][8]
set -euo pipefail
IFS=\$'\\n\\t'

# Script constants
readonly SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="\$(basename "\${BASH_SOURCE[0]}")"
readonly LOG_FILE="\${SCRIPT_DIR}/\${SCRIPT_NAME%.*}.log"
readonly REPOS_DIR="$REPOS_DIR"
readonly SCRIPTS_DIR="$SCRIPTS_DIR"
readonly LOCAL_BIN="$LOCAL_BIN"
readonly BASHRC_PATH="$BASHRC_PATH"

# Color codes for output
readonly RED='\\033[0;31m'
readonly GREEN='\\033[0;32m'
readonly YELLOW='\\033[1;33m'
readonly BLUE='\\033[0;34m'
readonly NC='\\033[0m' # No Color

# Logging functions
log_message() {
    local level="\$1"
    local message="\$2"
    local timestamp=\$(date +"%Y-%m-%d %H:%M:%S")
    echo "[\${timestamp}] [\${level}] \${message}" | tee -a "\$LOG_FILE"
}

log_info() { log_message "INFO" "\$1"; }
log_warning() { log_message "WARNING" "\$1"; }
log_error() { log_message "ERROR" "\$1"; }

# Error handling function
handle_error() {
    local line_number="\$1"
    log_error "Script failed at line \$line_number"
    cleanup
    exit 1
}

# Cleanup function
cleanup() {
    log_info "Performing cleanup..."
    # Add cleanup logic here
}

# Input validation function
validate_input() {
    local input="\$1"
    local pattern="\${2:-.*}"
    
    if [[ ! "\$input" =~ \$pattern ]]; then
        log_error "Invalid input: \$input"
        return 1
    fi
    echo "\$input"
}

# Safe file operations
create_backup() {
    local file="\$1"
    if [[ -f "\$file" ]]; then
        local backup_file="\${file}.backup.\$(date +%Y%m%d_%H%M%S)"
        if cp "\$file" "\$backup_file"; then
            log_info "Created backup: \$backup_file"
        else
            log_error "Failed to create backup of \$file"
            return 1
        fi
    fi
}

# Confirmation prompt function
confirm_action() {
    local prompt="\$1"
    read -p "\${prompt} (y/N): " -n 1 -r
    echo
    [[ \$REPLY =~ ^[Yy]\$ ]]
}

# Dry run function
dry_run_command() {
    if [[ "\${DRY_RUN:-false}" == "true" ]]; then
        printf -v cmd_str '%q ' "\$@"
        echo "DRY RUN: Would execute: \$cmd_str" >&2
        return 0
    else
        "\$@"
    fi
}

# Path validation with creation
validate_paths() {
    local paths=("\$REPOS_DIR" "\$SCRIPTS_DIR" "\$LOCAL_BIN")
    
    for path in "\${paths[@]}"; do
        if [[ ! -d "\$path" ]]; then
            log_warning "Directory does not exist: \$path"
            if confirm_action "Create directory \$path?"; then
                if mkdir -p "\$path"; then
                    log_info "Created directory: \$path"
                else
                    log_error "Failed to create directory: \$path"
                    return 1
                fi
            fi
        fi
    done
}

# Safe file permission check
get_file_permissions() {
    local file="\$1"
    if [[ -f "\$file" ]]; then
        stat -c "%A" "\$file" 2>/dev/null || ls -la "\$file" | cut -d' ' -f1
    else
        echo "File not found"
    fi
}

# Main script usage
script_usage() {
    cat << 'USAGE_EOF'
Usage: \$SCRIPT_NAME [OPTIONS]

Description:
    ${script_description:-"Generated script template"}

Options:
    -h, --help       Show this help message
    -v, --verbose    Enable verbose output
    -d, --dry-run    Show what would be done without executing
    --version        Show version information

Examples:
    \$SCRIPT_NAME --help
    \$SCRIPT_NAME --dry-run

USAGE_EOF
}

# Parameter parsing
parse_params() {
    local verbose=false
    
    while [[ \$# -gt 0 ]]; do
        case \$1 in
            -h|--help)
                script_usage
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                set -x
                shift
                ;;
            -d|--dry-run)
                export DRY_RUN=true
                log_info "Dry run mode enabled"
                shift
                ;;
            --version)
                echo "\$SCRIPT_NAME version 1.0.0"
                exit 0
                ;;
            *)
                log_error "Unknown parameter: \$1"
                script_usage
                exit 1
                ;;
        esac
    done
    
    if [[ "\$verbose" == "true" ]]; then
        log_info "Verbose mode enabled"
    fi
}

# Main function
main() {
    # Set error handling
    trap 'handle_error \$LINENO' ERR
    trap cleanup EXIT
    
    log_info "Starting \$SCRIPT_NAME"
    
    # Validate environment paths
    validate_paths
    
    # Add your main script logic here
    log_info "Script logic goes here"
    
    # Example of using confirmation for dangerous operations
    if confirm_action "Perform potentially dangerous operation?"; then
        log_info "User confirmed dangerous operation"
        # dry_run_command rm -rf /some/important/file
    else
        log_info "User cancelled dangerous operation"
    fi
    
    log_info "Script completed successfully"
}

# Script entry point
if [[ "\${BASH_SOURCE[0]}" == "\${0}" ]]; then
    parse_params "\$@"
    main "\$@"
fi
EOF
    
    # Validate with shellcheck if available[1]
    if command -v shellcheck >/dev/null 2>&1; then
        echo "Validating script with shellcheck..."
        if shellcheck "$temp_file"; then
            echo -e "\033[0;32m✓ Shellcheck validation passed\033[0m"
        else
            echo -e "\033[0;31m✗ Shellcheck validation failed\033[0m" >&2
            if ! confirm_action "Continue despite shellcheck warnings?"; then
                return 1
            fi
        fi
    else
        echo -e "\033[1;33mWarning: shellcheck not found. Install for better validation.\033[0m" >&2
    fi
    
    # Show dry run output
    if [[ "$dry_run" == "true" ]]; then
        echo -e "\033[0;34m=== DRY RUN MODE - Generated Script Preview ===\033[0m"
        echo "Would create file: $output_file"
        echo "Script size: $(wc -l < "$temp_file") lines"
        echo -e "\033[0;34m=== Script Content Preview (first 20 lines) ===\033[0m"
        head -20 "$temp_file"
        echo -e "\033[0;34m=== End Preview ===\033[0m"
    else
        # Create output directory if needed
        mkdir -p "$(dirname "$output_file")"
        
        # Copy generated script to final location
        if cp "$temp_file" "$output_file" && chmod +x "$output_file"; then
            echo -e "\033[0;32m✓ Script generated: $output_file\033[0m"
        else
            echo -e "\033[0;31m✗ Failed to create script\033[0m" >&2
            return 1
        fi
        
        # Copy to clipboard - fixed SC2119[2]
        if cb < "$temp_file"; then
            echo -e "\033[0;32m✓ Script copied to clipboard\033[0m"
        fi
        
        # Summary with safe file permission check
        echo -e "\033[0;34m=== Generation Summary ===\033[0m"
        echo "Script name: $script_name"
        echo "Description: ${script_description:-"None provided"}"
        echo "Author: $author"
        echo "Output file: $output_file"
        echo "File size: $(wc -l < "$output_file") lines"
        echo "Permissions: $(get_file_permissions "$output_file")"
    fi
}
