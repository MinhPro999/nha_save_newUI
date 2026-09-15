#!/bin/bash

#=============================================================================
# Flutter Project Setup Verification Script
# Checks if all required tools are installed with correct versions
#=============================================================================

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$PROJECT_DIR/tool/flutter_env.sh"
cd "$PROJECT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASS=0
FAIL=0
WARN=0

#=============================================================================
# Helper Functions
#=============================================================================

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    PASS=$((PASS + 1))
}

print_fail() {
    echo -e "${RED}❌ $1${NC}"
    FAIL=$((FAIL + 1))
}

print_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    WARN=$((WARN + 1))
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

#=============================================================================
# Version Checking Functions
#=============================================================================

check_flutter() {
    print_header "Checking Flutter"

    if command -v flutter &> /dev/null; then
        FLUTTER_VERSION=$(flutter --version | head -n 1)
        echo "$FLUTTER_VERSION"

        if echo "$FLUTTER_VERSION" | grep -q "3.41.6"; then
            print_success "Flutter 3.41.6 installed"
        else
            print_warn "Flutter version is $(echo $FLUTTER_VERSION | awk '{print $2}'), expected 3.41.6"
        fi
    else
        print_fail "Flutter not found. Add to PATH: export PATH=\"\$HOME/development/flutter/bin:\$PATH\""
    fi
}

check_dart() {
    print_header "Checking Dart"

    if command -v dart &> /dev/null; then
        DART_VERSION=$(dart --version 2>&1 | sed -E 's/.*version: ([^ ]+).*/\1/')
        echo "Dart version: $DART_VERSION"

        if echo "$DART_VERSION" | grep -q "3.11.4"; then
            print_success "Dart 3.11.4 installed (bundled with Flutter)"
        else
            print_info "Dart version: $DART_VERSION (bundled with Flutter)"
        fi
    else
        print_warn "Dart not directly accessible (should come with Flutter)"
    fi
}

check_xcode() {
    print_header "Checking Xcode"

    if command -v xcodebuild &> /dev/null; then
        XCODE_VERSION=$(xcodebuild -version | head -n 1)
        echo "$XCODE_VERSION"

        if echo "$XCODE_VERSION" | grep -qE "1[5-9]\.|[2-9][0-9]\."; then
            print_success "Xcode 15 or later installed"
        else
            print_warn "Xcode version is $(echo $XCODE_VERSION | awk '{print $2}'), minimum 15 required for iOS 17"
        fi
    else
        print_fail "Xcode not found. Install via App Store or: xcode-select --install"
    fi
}

check_java() {
    print_header "Checking Java/JDK"

    if command -v java &> /dev/null; then
        JAVA_VERSION=$(java -version 2>&1 | grep -m 1 -E '^(openjdk|java) version' || true)
        echo "$JAVA_VERSION"

        if echo "$JAVA_VERSION" | grep -qE "17|18|19|20|21|25"; then
            print_success "Java 17+ installed"
        else
            print_warn "Java version may be too old. Minimum Java 17 required"
        fi
    else
        print_fail "Java/JDK not found. Install: brew install openjdk@21"
    fi
}

check_cocoapods() {
    print_header "Checking CocoaPods"

    if command -v pod &> /dev/null; then
        POD_VERSION=$(pod --version)
        echo "CocoaPods version: $POD_VERSION"

        if echo "$POD_VERSION" | grep -qE "1\.1[5-9]|1\.[2-9]"; then
            print_success "CocoaPods 1.15+ installed"
        else
            print_warn "CocoaPods version is $POD_VERSION, recommended 1.15+"
        fi
    else
        print_fail "CocoaPods not found. Install: sudo gem install cocoapods"
    fi
}

check_android_sdk() {
    print_header "Checking Android SDK"

    if [ -n "$ANDROID_HOME" ]; then
        echo "ANDROID_HOME: $ANDROID_HOME"

        if [ -d "$ANDROID_HOME/platforms/android-35" ]; then
            print_success "Android SDK API 35 found"
        else
            print_warn "Android SDK API 35 not found. Install via Android Studio"
        fi

        if [ -d "$ANDROID_HOME/build-tools" ]; then
            BUILD_TOOLS=$(ls -1 "$ANDROID_HOME/build-tools" | sort -V | tail -n 1)
            echo "Latest Build Tools: $BUILD_TOOLS"
            print_success "Android Build Tools found"
        else
            print_warn "Android Build Tools not found"
        fi
    else
        print_fail "ANDROID_HOME not set. Add to ~/.zshrc: export ANDROID_HOME=\$HOME/Library/Android/sdk"
    fi
}

check_gradle() {
    print_header "Checking Gradle (via wrapper)"

    if [ -f "android/gradlew" ]; then
        GRADLE_VERSION=$(./android/gradlew --version 2>/dev/null | grep -m 1 '^Gradle ' || echo "Unknown")
        echo "$GRADLE_VERSION"
        print_success "Gradle wrapper available"
    else
        print_warn "Gradle wrapper not found in android/gradlew"
    fi
}

check_flutter_doctor() {
    print_header "Running flutter doctor"

    flutter doctor -v 2>&1 | head -n 30
    echo "..."
}

check_project_files() {
    print_header "Checking Project Files"

    # Check pubspec.yaml
    if [ -f "pubspec.yaml" ]; then
        print_success "pubspec.yaml found"
    else
        print_fail "pubspec.yaml not found"
    fi

    # Check pubspec.lock
    if [ -f "pubspec.lock" ]; then
        print_success "pubspec.lock found (dependency versions locked)"
    else
        print_warn "pubspec.lock not found (will be created by flutter pub get)"
    fi

    if [ -f "assets/images/projects/modern_townhouse.jpg" ]; then
        print_success "Local project artwork found"
    else
        print_fail "Local project artwork is missing"
    fi
}

check_dependencies() {
    print_header "Checking Project Dependencies"

    if [ -f "pubspec.lock" ]; then
        # Count packages
        PACKAGE_COUNT=$(grep -c "^  [a-z_].*:" pubspec.lock || echo "0")
        echo "Total packages in lock file: ~$PACKAGE_COUNT"
        print_success "Dependencies locked and ready"
    else
        print_info "Running 'flutter pub get' to fetch dependencies..."
        flutter pub get
        print_success "Dependencies fetched"
    fi
}

#=============================================================================
# Main Execution
#=============================================================================

main() {
    if [[ -t 1 ]] && command -v clear &> /dev/null; then
        clear
    fi

    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║   Flutter Project Setup Verification                          ║"
    echo "║   Project: Construction Plan                                  ║"
    echo "║   Date: $(date '+%Y-%m-%d %H:%M:%S')                                      ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    # Check all tools
    check_flutter
    check_dart
    check_xcode
    check_java
    check_cocoapods
    check_android_sdk
    check_gradle
    check_project_files
    check_dependencies
    check_flutter_doctor

    # Final summary
    print_header "VERIFICATION SUMMARY"

    echo -e "${GREEN}✅ Passed: $PASS${NC}"
    if [ $WARN -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Warnings: $WARN${NC}"
    fi
    if [ $FAIL -gt 0 ]; then
        echo -e "${RED}❌ Failed: $FAIL${NC}"
    fi

    echo ""

    if [ $FAIL -eq 0 ]; then
        echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}✅ SETUP VERIFICATION PASSED!${NC}"
        echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
        echo ""
        echo "You can now run:"
        echo -e "  ${BLUE}tool/flutter_local.sh run --flavor dev -t lib/main_dev.dart${NC}"
        echo ""
    else
        echo -e "${RED}═══════════════════════════════════════════════════════${NC}"
        echo -e "${RED}❌ SETUP HAS ISSUES - FIX ABOVE ERRORS FIRST${NC}"
        echo -e "${RED}═══════════════════════════════════════════════════════${NC}"
        echo ""
        echo "See TROUBLESHOOTING_GUIDE.md for help"
        echo ""
    fi

    if [ $WARN -gt 0 ]; then
        echo "⚠️  Review warnings above before proceeding"
        echo ""
    fi
}

# Run main function
main
