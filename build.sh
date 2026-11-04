#!/usr/bin/env bash
# Build the pomo CLI and install it on the path.
# Copies the new binary to ~/.local/bin if it isn't already there.

set -euo pipefail

# Build in release mode
echo "Building pomo (release)..."
swift build -c release

# Determine the binary path
BINARY=".build/out/Products/Release/pomo"

# Check if binary was built
if [[ ! -f "$BINARY" ]]; then
    echo "Build failed: binary not found at $BINARY"
    exit 1
fi

echo "Build complete: $BINARY"

# Install to ~/.local/bin
BIN_DIR="$HOME/.local/bin"
if [[ ! -d "$BIN_DIR" ]]; then
    echo "Creating $BIN_DIR..."
    mkdir -p "$BIN_DIR"
fi

cp -f "$BINARY" "$BIN_DIR/pomo"
echo "Installed: $BIN_DIR/pomo"

# Verify it's on the path
if command -v pomo &>/dev/null; then
    echo "pomo is now available on your path."
else
    echo ""
    echo "Note: $BIN_DIR is not in your PATH. Add it with:"
    echo "  echo 'export PATH=\"$HOME/.local/bin:\$PATH\"' >> ~/.zshrc"
    echo "  source ~/.zshrc"
fi