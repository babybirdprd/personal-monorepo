#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

# --- 1. Ensure pnpm is installed ---
# Jules usually has Node, but we ensure pnpm is explicitly available.
if ! command -v pnpm &> /dev/null; then
    echo "pnpm not found. Installing pnpm..."
    npm install -g pnpm
else
    echo "pnpm is already installed: $(pnpm --version)"
fi

# --- 2. Install Tauri v2 System Dependencies (Linux) ---
# Critical: Tauri v2 requires libwebkit2gtk-4.1-dev (v1 used 4.0).
# We also install headers for cross-compilation checks.
echo "Installing Linux system dependencies..."
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -qq
sudo apt-get install -y -qq \
    build-essential \
    curl \
    wget \
    file \
    libssl-dev \
    libgtk-3-dev \
    libayatana-appindicator3-dev \
    librsvg2-dev \
    libwebkit2gtk-4.1-dev \
    llvm \
    clang
