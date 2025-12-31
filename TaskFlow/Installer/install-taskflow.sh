#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════════
# TaskFlow Installer Script
# © 2025 Pezz. All rights reserved.
# 
# This script installs TaskFlow and its dependencies (Ollama + gemma3:1b model)
# ═══════════════════════════════════════════════════════════════════════════════

set -e

# Version and Copyright
APP_VERSION="1.1.0"
COPYRIGHT="© 2025 Pezz. All rights reserved."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
TASKFLOW_APP_NAME="TaskFlow.app"
OLLAMA_DOWNLOAD_URL="https://ollama.com/download/Ollama-darwin.zip"
INSTALL_DIR="/Applications"
TEMP_DIR=$(mktemp -d)

# Default model - gemma3:1b is fast and capable
DEFAULT_MODEL="gemma3:1b"

# Cleanup function
cleanup() {
    echo -e "\n${YELLOW}Cleaning up temporary files...${NC}"
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Print banner
print_banner() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║              ████████╗ █████╗ ███████╗██╗  ██╗               ║"
    echo "║              ╚══██╔══╝██╔══██╗██╔════╝██║ ██╔╝               ║"
    echo "║                 ██║   ███████║███████╗█████╔╝                ║"
    echo "║                 ██║   ██╔══██║╚════██║██╔═██╗                ║"
    echo "║                 ██║   ██║  ██║███████║██║  ██╗               ║"
    echo "║                 ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝               ║"
    echo "║                                                              ║"
    echo "║              ███████╗██╗      ██████╗ ██╗    ██╗             ║"
    echo "║              ██╔════╝██║     ██╔═══██╗██║    ██║             ║"
    echo "║              █████╗  ██║     ██║   ██║██║ █╗ ██║             ║"
    echo "║              ██╔══╝  ██║     ██║   ██║██║███╗██║             ║"
    echo "║              ██║     ███████╗╚██████╔╝╚███╔███╔╝             ║"
    echo "║              ╚═╝     ╚══════╝ ╚═════╝  ╚══╝╚══╝              ║"
    echo "║                                                              ║"
    echo "║                    INSTALLER v$APP_VERSION                          ║"
    echo "║              © 2025 Pezz. All rights reserved.               ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Print step header
print_step() {
    local step_num=$1
    local step_title=$2
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  Step $step_num: $step_title${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# Print progress
print_progress() {
    echo -e "${BLUE}→${NC} $1"
}

# Print success
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Print warning
print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Print error
print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check system requirements
check_requirements() {
    print_step 1 "Checking System Requirements"
    
    # Check macOS version
    print_progress "Checking macOS version..."
    macos_version=$(sw_vers -productVersion)
    major_version=$(echo "$macos_version" | cut -d. -f1)
    
    if [ "$major_version" -lt 13 ]; then
        print_error "TaskFlow requires macOS 13 (Ventura) or later. You have macOS $macos_version"
        exit 1
    fi
    print_success "macOS $macos_version detected (compatible)"
    
    # Check architecture
    print_progress "Checking processor architecture..."
    arch=$(uname -m)
    if [ "$arch" = "arm64" ]; then
        print_success "Apple Silicon (M1/M2/M3) detected - optimal performance"
    elif [ "$arch" = "x86_64" ]; then
        print_success "Intel processor detected - compatible"
    else
        print_error "Unknown architecture: $arch"
        exit 1
    fi
    
    # Check available disk space
    print_progress "Checking available disk space..."
    available_space=$(df -g / | awk 'NR==2 {print $4}')
    if [ "$available_space" -lt 5 ]; then
        print_warning "Low disk space: ${available_space}GB available. Recommend at least 5GB for the model."
    else
        print_success "${available_space}GB available disk space"
    fi
    
    # Check for existing Ollama installation
    print_progress "Checking for existing Ollama installation..."
    if command -v ollama &> /dev/null; then
        ollama_version=$(ollama --version 2>/dev/null || echo "unknown")
        print_success "Ollama already installed: $ollama_version"
        OLLAMA_INSTALLED=true
    else
        print_warning "Ollama not found - will be installed"
        OLLAMA_INSTALLED=false
    fi
}

# Install Ollama
install_ollama() {
    print_step 2 "Installing Ollama"
    
    if [ "$OLLAMA_INSTALLED" = true ]; then
        print_success "Ollama is already installed, skipping..."
        
        # Make sure Ollama is running
        print_progress "Ensuring Ollama is running..."
        if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
            print_progress "Starting Ollama service..."
            open -a Ollama
            
            local max_attempts=30
            local attempt=0
            while ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; do
                sleep 2
                ((attempt++))
                if [ $attempt -ge $max_attempts ]; then
                    print_error "Ollama failed to start. Please try starting it manually."
                    exit 1
                fi
                echo -n "."
            done
            echo ""
        fi
        print_success "Ollama is running"
        return
    fi
    
    print_progress "Downloading Ollama..."
    curl -L -# "$OLLAMA_DOWNLOAD_URL" -o "$TEMP_DIR/Ollama.zip"
    
    print_progress "Extracting Ollama..."
    unzip -q "$TEMP_DIR/Ollama.zip" -d "$TEMP_DIR"
    
    print_progress "Installing Ollama to /Applications..."
    if [ -d "/Applications/Ollama.app" ]; then
        print_warning "Removing existing Ollama installation..."
        rm -rf "/Applications/Ollama.app"
    fi
    mv "$TEMP_DIR/Ollama.app" "/Applications/"
    
    print_progress "Starting Ollama service..."
    open -a Ollama
    
    # Wait for Ollama to start
    print_progress "Waiting for Ollama to initialize..."
    local max_attempts=30
    local attempt=0
    while ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; do
        sleep 2
        ((attempt++))
        if [ $attempt -ge $max_attempts ]; then
            print_error "Ollama failed to start. Please try starting it manually."
            exit 1
        fi
        echo -n "."
    done
    echo ""
    
    print_success "Ollama installed and running"
}

# Download LLM model
download_model() {
    print_step 3 "Downloading LLM Model"
    
    echo -e "TaskFlow uses the ${CYAN}gemma3:1b${NC} model for intelligent task title generation."
    echo -e "This model runs entirely on your Mac - ${GREEN}no internet required after installation${NC}.\n"
    echo -e "Model: ${YELLOW}gemma3:1b${NC} (~1.5GB download)"
    echo -e "This is a fast and capable model optimized for quick title generation.\n"
    
    # Check if model already exists
    if ollama list 2>/dev/null | grep -q "gemma3:1b"; then
        print_success "gemma3:1b is already downloaded"
        return
    fi
    
    print_progress "Downloading gemma3:1b model..."
    echo -e "${YELLOW}This may take a few minutes depending on your internet connection.${NC}\n"
    
    # Download the model
    if ollama pull "$DEFAULT_MODEL"; then
        print_success "gemma3:1b downloaded successfully"
    else
        print_error "Failed to download gemma3:1b"
        echo -e "${YELLOW}You can try downloading it later with: ollama pull gemma3:1b${NC}"
    fi
}

# Install TaskFlow app
install_taskflow() {
    print_step 4 "Installing TaskFlow"
    
    # Get the directory where this script is located
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    
    # Check if TaskFlow.app exists in the same directory
    if [ -d "$SCRIPT_DIR/$TASKFLOW_APP_NAME" ]; then
        print_progress "Found TaskFlow.app in installer directory"
        SOURCE_APP="$SCRIPT_DIR/$TASKFLOW_APP_NAME"
    elif [ -d "./$TASKFLOW_APP_NAME" ]; then
        print_progress "Found TaskFlow.app in current directory"
        SOURCE_APP="./$TASKFLOW_APP_NAME"
    else
        print_error "TaskFlow.app not found. Please ensure it's in the same directory as this installer."
        exit 1
    fi
    
    print_progress "Installing TaskFlow to /Applications..."
    
    if [ -d "$INSTALL_DIR/$TASKFLOW_APP_NAME" ]; then
        print_warning "Removing existing TaskFlow installation..."
        rm -rf "$INSTALL_DIR/$TASKFLOW_APP_NAME"
    fi
    
    cp -R "$SOURCE_APP" "$INSTALL_DIR/"
    
    # Remove quarantine attribute
    print_progress "Removing quarantine attribute..."
    xattr -rd com.apple.quarantine "$INSTALL_DIR/$TASKFLOW_APP_NAME" 2>/dev/null || true
    
    print_success "TaskFlow installed to /Applications"
}

# Configure permissions
configure_permissions() {
    print_step 5 "Configuring Permissions"
    
    echo -e "TaskFlow requires the following permissions to function:\n"
    echo -e "  ${CYAN}1.${NC} Screen Recording - to capture screenshots"
    echo -e "  ${CYAN}2.${NC} Accessibility - for keyboard shortcuts\n"
    
    print_progress "Opening System Settings for Screen Recording permission..."
    echo -e "\n${YELLOW}Please grant Screen Recording permission to TaskFlow when prompted.${NC}"
    echo -e "${YELLOW}You may need to restart TaskFlow after granting permissions.${NC}\n"
    
    # Open System Settings to Screen Recording
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
    
    echo -n "Press Enter when you've granted the permission..."
    read -r
    
    print_success "Permission configuration complete"
}

# Final summary
print_summary() {
    print_step 6 "Installation Complete!"
    
    echo -e "${GREEN}TaskFlow has been successfully installed!${NC}\n"
    
    echo "Installed components:"
    echo -e "  ${GREEN}✓${NC} TaskFlow.app → /Applications/TaskFlow.app"
    if [ "$OLLAMA_INSTALLED" = false ]; then
        echo -e "  ${GREEN}✓${NC} Ollama.app → /Applications/Ollama.app"
    fi
    echo -e "  ${GREEN}✓${NC} gemma3:1b model for AI-powered task titles"
    echo ""
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  Quick Start Guide${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    echo "1. Launch TaskFlow from your Applications folder or Launchpad"
    echo "2. Grant Screen Recording permission when prompted"
    echo "3. Click the capture button (or use ⌘⇧C) to create your first task"
    echo "4. Use the menu bar icon for quick access"
    echo ""
    
    echo -e "${YELLOW}Note:${NC} Ollama must be running for AI-powered title generation."
    echo -e "      It starts automatically and runs in the background.\n"
    
    echo -n "Would you like to launch TaskFlow now? [Y/n]: "
    read -r launch_choice
    
    if [ "$launch_choice" != "n" ] && [ "$launch_choice" != "N" ]; then
        print_progress "Launching TaskFlow..."
        open -a TaskFlow
        print_success "TaskFlow is now running!"
    fi
    
    echo -e "\n${PURPLE}Thank you for installing TaskFlow!${NC}"
    echo -e "${PURPLE}Enjoy your productivity boost! 🚀${NC}\n"
}

# Main installation flow
main() {
    print_banner
    
    echo -e "Welcome to the TaskFlow installer!\n"
    echo -e "This installer will set up TaskFlow and all required components"
    echo -e "for ${GREEN}100% offline operation${NC} - no internet needed after installation.\n"
    
    echo -n "Press Enter to continue or 'q' to quit: "
    read -r choice
    if [ "$choice" = "q" ] || [ "$choice" = "Q" ]; then
        echo -e "\n${YELLOW}Installation cancelled.${NC}"
        exit 0
    fi
    
    check_requirements
    install_ollama
    download_model
    install_taskflow
    configure_permissions
    print_summary
}

# Run main
main "$@"
