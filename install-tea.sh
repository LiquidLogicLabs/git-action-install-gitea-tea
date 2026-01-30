#!/bin/bash
set -euo pipefail

# Get inputs from environment variables
VERSION="${INPUT_VERSION:-latest}"
USERNAME="${INPUT_USERNAME:-}"
TOKEN="${INPUT_TOKEN:-}"
REPO="${INPUT_REPO:-}"
VERBOSE="${INPUT_VERBOSE:-false}"

# Enable verbose mode if requested
if [ "$VERBOSE" = "true" ]; then
  set -x
  echo "[DEBUG] Verbose logging enabled"
  echo "[DEBUG] version=${VERSION}"
  echo "[DEBUG] username=${USERNAME:-<unset>}"
  echo "[DEBUG] repo=${REPO:-<unset>}"
fi

# Set defaults from GitHub context if not provided
if [ -z "$USERNAME" ]; then
  USERNAME="${GITHUB_ACTOR:-}"
fi

if [ -z "$REPO" ]; then
  if [ -n "${GITHUB_SERVER_URL:-}" ] && [ -n "${GITHUB_REPOSITORY_OWNER:-}" ]; then
    REPO="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY_OWNER}"
  else
    REPO="https://gitea.com"
  fi
fi

# Resolve token: input token → GITEA_TOKEN → GITHUB_TOKEN
if [ -z "$TOKEN" ]; then
  if [ -n "${GITEA_TOKEN:-}" ]; then
    TOKEN="$GITEA_TOKEN"
  elif [ -n "${GITHUB_TOKEN:-}" ]; then
    TOKEN="$GITHUB_TOKEN"
  fi
fi

# Determine the latest version if 'latest' is specified
if [ "$VERSION" = "latest" ]; then
  echo "Fetching latest tea version..."
  if ! command -v jq &> /dev/null; then
    echo "Error: jq is required to fetch latest version but is not installed"
    exit 1
  fi
  VERSION=$(curl -s https://gitea.com/api/v1/repos/gitea/tea/releases/latest | jq -r .tag_name)
  if [ -z "$VERSION" ] || [ "$VERSION" = "null" ]; then
    echo "Error: Failed to fetch latest version from Gitea API"
    exit 1
  fi
  # Remove 'v' prefix if present
  VERSION="${VERSION#v}"
fi

# Remove 'v' prefix if present in version
VERSION="${VERSION#v}"

echo "Installing tea version: $VERSION"

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
  x86_64)
    ARCH="amd64"
    ;;
  aarch64|arm64)
    ARCH="arm64"
    ;;
  *)
    echo "Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

# Download URL format: https://gitea.com/gitea/tea/releases/download/v0.11.1/tea-0.11.1-linux-amd64
DOWNLOAD_URL="https://gitea.com/gitea/tea/releases/download/v${VERSION}/tea-${VERSION}-linux-${ARCH}"
INSTALL_DIR="/usr/local/bin"
INSTALL_PATH="${INSTALL_DIR}/tea"

echo "Downloading tea from: $DOWNLOAD_URL"
curl -L -f "$DOWNLOAD_URL" -o "$INSTALL_PATH" || {
  echo "Failed to download tea binary"
  exit 1
}

chmod +x "$INSTALL_PATH"

# Verify installation
if ! "$INSTALL_PATH" --version &> /dev/null; then
  echo "Error: tea binary is not executable or failed to run"
  exit 1
fi

# Extract version from tea --version output
# Format: "Version: 0.11.1	golang: 1.24.4" (may contain ANSI color codes)
# Strip ANSI codes and extract version after "Version:"
VERSION_OUTPUT=$("$INSTALL_PATH" --version 2>&1 | head -n1)
INSTALLED_VERSION=$(echo "$VERSION_OUTPUT" | sed 's/\x1b\[[0-9;]*m//g' | sed -E 's/.*Version:[[:space:]]*v?([0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+)?).*/\1/' || echo "")
if [ -z "$INSTALLED_VERSION" ] || [ "$INSTALLED_VERSION" = "$VERSION_OUTPUT" ]; then
  # Fallback: try to extract first version number (for different output formats)
  INSTALLED_VERSION=$(echo "$VERSION_OUTPUT" | sed 's/\x1b\[[0-9;]*m//g' | sed -E 's/.*v?([0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+)?).*/\1/' || echo "")
fi
if [ -z "$INSTALLED_VERSION" ] || [ "$INSTALLED_VERSION" = "$VERSION_OUTPUT" ]; then
  # Final fallback to the version we tried to install
  INSTALLED_VERSION="$VERSION"
fi

echo "tea installed successfully at: $INSTALL_PATH"
echo "Installed version: $INSTALLED_VERSION"

# Configure authentication if both token and repo are provided
if [ -n "$TOKEN" ] && [ -n "$REPO" ]; then
  echo "Configuring tea authentication..."
  # Mask token in logs
  echo "::add-mask::$TOKEN"
  
  # Add login configuration
  "$INSTALL_PATH" login add --name default --url "$REPO" --token "$TOKEN" || {
    echo "Warning: Failed to configure tea authentication. Continuing anyway."
  }
  echo "tea authentication configured for: $REPO"
elif [ -n "$TOKEN" ] && [ -z "$REPO" ]; then
  echo "Warning: Token provided but no repository URL. Skipping authentication configuration."
  echo "Note: tea defaults to http://localhost:3000 if no URL is provided, which won't work in GitHub Actions."
elif [ -z "$TOKEN" ]; then
  echo "No token provided, skipping authentication configuration"
fi

# Set outputs
{
  echo "success=true"
  echo "binaryPath=$INSTALL_PATH"
  echo "version=$INSTALLED_VERSION"
} >> "$GITHUB_OUTPUT"

echo "Installation complete!"
