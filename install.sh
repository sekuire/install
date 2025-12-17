#!/bin/bash
# Sekuire CLI Installer
# Usage: curl -fsSL https://install.sekuire.com | sh

set -e

# Configuration
INSTALL_DIR="${SEKUIRE_INSTALL_DIR:-$HOME/.sekuire/bin}"
BINARY_NAME="sekuire"
REPO="sekuire/releases"
GITHUB_API="https://api.github.com/repos/${REPO}/releases/latest"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
log_step() { echo -e "${BLUE}==>${NC} $1"; }

# Detect platform and architecture
detect_platform() {
    OS="$(uname -s)"
    ARCH="$(uname -m)"

    case "$OS" in
        Linux*)
            PLATFORM="linux"
            ;;
        Darwin*)
            PLATFORM="darwin"
            ;;
        *)
            log_error "Unsupported operating system: $OS"
            ;;
    esac

    case "$ARCH" in
        x86_64|amd64)
            ARCHITECTURE="amd64"
            ;;
        aarch64|arm64)
            ARCHITECTURE="arm64"
            ;;
        *)
            log_error "Unsupported architecture: $ARCH"
            ;;
    esac

    BINARY_TARGET="${BINARY_NAME}-${PLATFORM}-${ARCHITECTURE}"
    log_info "Detected platform: ${PLATFORM}-${ARCHITECTURE}"
}

# Get latest release version
get_latest_version() {
    log_step "Fetching latest version..."

    if command -v curl >/dev/null 2>&1; then
        VERSION=$(curl -fsSL "$GITHUB_API" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/' | head -1)
    elif command -v wget >/dev/null 2>&1; then
        VERSION=$(wget -qO- "$GITHUB_API" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/' | head -1)
    else
        log_error "Neither curl nor wget found. Please install one of them."
    fi

    if [ -z "$VERSION" ]; then
        log_error "Failed to fetch latest version"
    fi

    log_info "Latest version: v${VERSION}"
}

# Download and verify binary
download_binary() {
    DOWNLOAD_URL="https://github.com/${REPO}/releases/download/v${VERSION}/${BINARY_TARGET}.tar.gz"
    CHECKSUM_URL="${DOWNLOAD_URL}.sha256"

    log_step "Downloading from: $DOWNLOAD_URL"

    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR"

    # Download binary
    if command -v curl >/dev/null 2>&1; then
        if ! curl -fsSL "$DOWNLOAD_URL" -o "${BINARY_TARGET}.tar.gz"; then
            log_error "Failed to download binary"
        fi
    elif command -v wget >/dev/null 2>&1; then
        if ! wget -q "$DOWNLOAD_URL" -O "${BINARY_TARGET}.tar.gz"; then
            log_error "Failed to download binary"
        fi
    fi

    # Download checksum
    if command -v curl >/dev/null 2>&1; then
        if ! curl -fsSL "$CHECKSUM_URL" -o "${BINARY_TARGET}.tar.gz.sha256"; then
            log_warn "Checksum file not found, skipping verification"
            SKIP_VERIFY=1
        fi
    elif command -v wget >/dev/null 2>&1; then
        if ! wget -q "$CHECKSUM_URL" -O "${BINARY_TARGET}.tar.gz.sha256"; then
            log_warn "Checksum file not found, skipping verification"
            SKIP_VERIFY=1
        fi
    fi

    # Verify checksum
    if [ -z "$SKIP_VERIFY" ]; then
        log_step "Verifying checksum..."
        if command -v sha256sum >/dev/null 2>&1; then
            sha256sum -c "${BINARY_TARGET}.tar.gz.sha256" || log_error "Checksum verification failed"
        elif command -v shasum >/dev/null 2>&1; then
            shasum -a 256 -c "${BINARY_TARGET}.tar.gz.sha256" || log_error "Checksum verification failed"
        else
            log_warn "No sha256 tool found, skipping verification"
        fi
        log_info "✓ Checksum verified"
    fi

    # Extract binary
    log_step "Extracting binary..."
    tar -xzf "${BINARY_TARGET}.tar.gz"

    # Make executable
    chmod +x "${BINARY_TARGET}"
}

# Install binary
install_binary() {
    log_step "Installing to: $INSTALL_DIR"

    # Create install directory
    mkdir -p "$INSTALL_DIR"

    # Move binary
    mv "${BINARY_TARGET}" "${INSTALL_DIR}/${BINARY_NAME}"

    # Cleanup
    cd - >/dev/null
    rm -rf "$TMP_DIR"

    log_info "✓ Binary installed successfully"
}

# Configure PATH
configure_path() {
    SHELL_RC=""

    # Detect shell
    case "$SHELL" in
        */bash)
            SHELL_RC="$HOME/.bashrc"
            # Also check .bash_profile on macOS
            if [ "$PLATFORM" = "darwin" ] && [ -f "$HOME/.bash_profile" ]; then
                SHELL_RC="$HOME/.bash_profile"
            fi
            ;;
        */zsh)
            SHELL_RC="$HOME/.zshrc"
            ;;
        */fish)
            SHELL_RC="$HOME/.config/fish/config.fish"
            ;;
        *)
            SHELL_RC="$HOME/.profile"
            ;;
    esac

    # Check if already in PATH
    if echo "$PATH" | grep -q "$INSTALL_DIR"; then
        log_info "✓ Install directory already in PATH"
        return
    fi

    # Add to PATH
    log_step "Adding $INSTALL_DIR to PATH in $SHELL_RC"

    if [ -f "$SHELL_RC" ]; then
        # Check if already added to RC file
        if ! grep -q "SEKUIRE_INSTALL" "$SHELL_RC"; then
            echo "" >> "$SHELL_RC"
            echo "# Sekuire CLI" >> "$SHELL_RC"
            echo "export PATH=\"\$HOME/.sekuire/bin:\$PATH\" # SEKUIRE_INSTALL" >> "$SHELL_RC"
            log_info "✓ PATH configuration added to $SHELL_RC"
        else
            log_info "✓ PATH already configured in $SHELL_RC"
        fi
    else
        # Create the file if it doesn't exist
        mkdir -p "$(dirname "$SHELL_RC")"
        echo "# Sekuire CLI" > "$SHELL_RC"
        echo "export PATH=\"\$HOME/.sekuire/bin:\$PATH\" # SEKUIRE_INSTALL" >> "$SHELL_RC"
        log_info "✓ Created $SHELL_RC with PATH configuration"
    fi

    # Add to current session
    export PATH="$INSTALL_DIR:$PATH"
}

# Verify installation
verify_installation() {
    log_step "Verifying installation..."

    if ! command -v "$BINARY_NAME" >/dev/null 2>&1; then
        log_warn "Binary not found in PATH. Please restart your shell or run:"
        echo "  source $SHELL_RC"
        echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
        return
    fi

    VERSION_OUTPUT=$("$BINARY_NAME" --version 2>&1 || true)
    log_info "✓ Installation successful!"
    echo ""
    echo "  $VERSION_OUTPUT"
    echo ""
    log_info "Get started with: ${BINARY_NAME} --help"
}

# Main installation flow
main() {
    echo ""
    echo "╔═══════════════════════════════════════╗"
    echo "║   Sekuire CLI Installer v1.0.0       ║"
    echo "╚═══════════════════════════════════════╝"
    echo ""

    detect_platform
    get_latest_version
    download_binary
    install_binary
    configure_path
    verify_installation

    echo ""
    log_info "Installation complete! 🎉"
    echo ""

    if ! command -v "$BINARY_NAME" >/dev/null 2>&1; then
        echo "⚠️  Restart your shell or run:"
        echo "   source $SHELL_RC"
    fi
}

# Run installer
main "$@"
