#!/bin/bash

# Build APK Script for Flutter Project
# Usage: ./build-apk.sh [prod|dev] [release|debug]

set -e

PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$PROJECT_DIR/tool/flutter_env.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
FLAVOR=${1:-prod}
BUILD_TYPE=${2:-release}

# Validate inputs
if [[ ! "$FLAVOR" =~ ^(prod|dev)$ ]]; then
    echo -e "${RED}❌ Error: Flavor must be 'prod' or 'dev'${NC}"
    echo "Usage: ./build-apk.sh [prod|dev] [release|debug]"
    exit 1
fi

if [[ ! "$BUILD_TYPE" =~ ^(release|debug)$ ]]; then
    echo -e "${RED}❌ Error: Build type must be 'release' or 'debug'${NC}"
    echo "Usage: ./build-apk.sh [prod|dev] [release|debug]"
    exit 1
fi

# Entry point mapping
if [ "$FLAVOR" == "dev" ]; then
    ENTRY_POINT="lib/main_dev.dart"
else
    ENTRY_POINT="lib/main_prod.dart"
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Flutter APK Build Script${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}📦 Flavor:${NC}      $FLAVOR"
echo -e "${YELLOW}🔧 Build Type:${NC}  $BUILD_TYPE"
echo -e "${YELLOW}📄 Entry Point:${NC} $ENTRY_POINT"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed or not in PATH${NC}"
    exit 1
fi

# Change to project directory
cd "$PROJECT_DIR"

# Android debug/release intermediates can temporarily consume several GB.
# Fail early with a clear message instead of Gradle's misleading package/copy errors.
AVAILABLE_KB=$(df -Pk "$PROJECT_DIR" | awk 'NR == 2 {print $4}')
MIN_FREE_KB=$((4 * 1024 * 1024))
if [ "$AVAILABLE_KB" -lt "$MIN_FREE_KB" ]; then
    AVAILABLE_GB=$(awk -v kb="$AVAILABLE_KB" 'BEGIN {printf "%.1f", kb / 1024 / 1024}')
    echo -e "${RED}❌ Not enough disk space: ${AVAILABLE_GB} GB available; at least 4 GB is required.${NC}"
    echo -e "${YELLOW}   Remove old generated builds with: flutter clean${NC}"
    exit 1
fi

# Get dependencies
echo -e "${YELLOW}📥 Getting dependencies...${NC}"
flutter pub get

# Build APK
echo ""
echo -e "${YELLOW}🏗️  Building APK...${NC}"
echo -e "${YELLOW}Flavor: $FLAVOR | Build Type: $BUILD_TYPE${NC}"
echo ""

flutter build apk \
    --flavor "$FLAVOR" \
    --"$BUILD_TYPE" \
    -t "$ENTRY_POINT"

# Show result
OUTPUT_FILE="build/app/outputs/flutter-apk/app-${FLAVOR}-${BUILD_TYPE}.apk"
if [ -f "$OUTPUT_FILE" ]; then
    SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
    echo ""
    echo -e "${GREEN}✅ APK Build Successful!${NC}"
    echo ""
    echo -e "${BLUE}📍 Output Location:${NC}"
    echo -e "${GREEN}   $PROJECT_DIR/$OUTPUT_FILE${NC}"
    echo ""
    echo -e "${BLUE}📊 File Size: ${GREEN}$SIZE${NC}"
    echo ""
    echo -e "${BLUE}📋 Install Command:${NC}"
    echo -e "${YELLOW}   adb install -r \"$OUTPUT_FILE\"${NC}"
    echo ""
else
    echo -e "${RED}❌ Error: APK file not found at expected location${NC}"
    echo -e "${YELLOW}   Expected: $OUTPUT_FILE${NC}"
    exit 1
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
