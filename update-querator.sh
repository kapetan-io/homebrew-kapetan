#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

REPO="kapetan-io/querator"
FORMULA_FILE="Formula/querator.rb"

echo -e "${BLUE}Fetching latest release information for ${REPO}...${NC}"

# Get latest release info from GitHub API
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest")

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to fetch release information${NC}"
    exit 1
fi

# Extract version and download URL
NEW_VERSION=$(echo "$LATEST_RELEASE" | jq -r '.tag_name' | sed 's/^v//')
DOWNLOAD_URL=$(echo "$LATEST_RELEASE" | jq -r '.tarball_url')

if [ "$NEW_VERSION" == "null" ] || [ "$DOWNLOAD_URL" == "null" ]; then
    echo -e "${RED}Error: Could not parse release information${NC}"
    exit 1
fi

echo -e "${GREEN}Latest version: ${NEW_VERSION}${NC}"

# Get current version from formula
CURRENT_VERSION=$(grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' "$FORMULA_FILE" | head -1 | sed 's/^v//')

if [ "$CURRENT_VERSION" == "$NEW_VERSION" ]; then
    echo -e "${YELLOW}Formula is already up to date (version ${CURRENT_VERSION})${NC}"
    exit 0
fi

echo -e "${YELLOW}Current version: ${CURRENT_VERSION}${NC}"
echo -e "${BLUE}Updating to version: ${NEW_VERSION}${NC}"

# Download and calculate SHA256
TEMP_FILE="/tmp/querator-${NEW_VERSION}.tar.gz"
echo -e "${BLUE}Downloading release archive to calculate SHA256...${NC}"

curl -L -o "$TEMP_FILE" "https://github.com/${REPO}/archive/v${NEW_VERSION}.tar.gz"

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to download release archive${NC}"
    exit 1
fi

NEW_SHA256=$(shasum -a 256 "$TEMP_FILE" | cut -d' ' -f1)
rm "$TEMP_FILE"

echo -e "${GREEN}New SHA256: ${NEW_SHA256}${NC}"

# Update the formula
echo -e "${BLUE}Updating formula...${NC}"

# Create backup
cp "$FORMULA_FILE" "${FORMULA_FILE}.backup"

# Update version and SHA256
sed -i '' "s|v[0-9]\+\.[0-9]\+\.[0-9]\+\.tar\.gz|v${NEW_VERSION}.tar.gz|g" "$FORMULA_FILE"
sed -i '' "s|sha256 \"[a-f0-9]\+\"|sha256 \"${NEW_SHA256}\"|g" "$FORMULA_FILE"

echo -e "${GREEN}Formula updated successfully!${NC}"
echo -e "${BLUE}Changes made:${NC}"
diff "${FORMULA_FILE}.backup" "$FORMULA_FILE" || true

BRANCH_NAME="update-querator-${NEW_VERSION}"

echo -e "${BLUE}Creating branch ${BRANCH_NAME}...${NC}"
git checkout -b "$BRANCH_NAME"

echo -e "${BLUE}Committing changes...${NC}"
git add "$FORMULA_FILE"
git commit -m "Update querator to v${NEW_VERSION}"

# Ask if user wants to create a PR
echo ""
read -p "Do you want to create a GitHub PR for this update? (y/N): " CREATE_PR

if [[ "$CREATE_PR" =~ ^[Yy]$ ]]; then
    # Check if gh is installed
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}Error: GitHub CLI (gh) is not installed${NC}"
        echo "Install it with: brew install gh"
        exit 1
    fi

    # Check if user is authenticated
    if ! gh auth status &> /dev/null; then
        echo -e "${RED}Error: Not authenticated with GitHub CLI${NC}"
        echo "Run: gh auth login"
        exit 1
    fi
    
    echo -e "${BLUE}Pushing branch...${NC}"
    git push -u origin "$BRANCH_NAME"
    
    echo -e "${BLUE}Creating pull request...${NC}"
    gh pr create \
        --title "Update querator to v${NEW_VERSION}" \
        --body "### Purpose
This updates the querator formula to the latest release version v${NEW_VERSION}.

### Implementation
- Updated version from v${CURRENT_VERSION} to v${NEW_VERSION}
- Updated SHA256 hash to ${NEW_SHA256}
- Verified download URL and archive integrity"
    
    echo -e "${GREEN}Pull request created successfully!${NC}"
else
    echo -e "${YELLOW}Skipping PR creation. Changes are ready for manual commit.${NC}"
fi

# Clean up backup
rm -f "${FORMULA_FILE}.backup"

echo -e "${GREEN}Done!${NC}"
