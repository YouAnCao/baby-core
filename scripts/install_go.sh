#!/bin/bash

# Install Go to user directory (no sudo required)
# For macOS ARM64

set -e

GO_VERSION="1.21.5"
GO_OS="darwin"
GO_ARCH="arm64"
GO_TAR="go${GO_VERSION}.${GO_OS}-${GO_ARCH}.tar.gz"
GO_URL="https://go.dev/dl/${GO_TAR}"
INSTALL_DIR="$HOME/.local"

echo "🚀 Installing Go ${GO_VERSION} for ${GO_OS}-${GO_ARCH}..."

# Set proxy
export https_proxy=http://127.0.0.1:7897
export http_proxy=http://127.0.0.1:7897
export all_proxy=socks5://127.0.0.1:7897

# Create installation directory
mkdir -p "$INSTALL_DIR"

# Download Go
echo "📥 Downloading Go..."
cd /tmp
curl -LO "$GO_URL"

# Extract
echo "📦 Extracting Go..."
tar -C "$INSTALL_DIR" -xzf "$GO_TAR"

# Clean up
rm "$GO_TAR"

echo "✅ Go installed to: $INSTALL_DIR/go"
echo ""
echo "Please add the following to your ~/.zshrc or ~/.bash_profile:"
echo ""
echo "  export PATH=\"\$HOME/.local/go/bin:\$PATH\""
echo "  export GOPATH=\"\$HOME/go\""
echo "  export PATH=\"\$GOPATH/bin:\$PATH\""
echo ""
echo "Then run: source ~/.zshrc"

