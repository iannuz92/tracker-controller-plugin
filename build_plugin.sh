#!/bin/bash

# Build Script for Tracker Controller Audio Unit Plugin
# Compatible with Mac M3 Pro and Apple Silicon

set -e  # Exit on any error

# Configuration
PROJECT_NAME="TrackerController"
SCHEME_HOST="TrackerControllerHost"
SCHEME_FRAMEWORK="TrackerControllerFramework"
SCHEME_AU="TrackerControllerAU"
BUILD_DIR="build"
CONFIGURATION="Release"
PLATFORM="macosx"
ARCH="arm64"  # Apple Silicon native

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Xcode
    if ! command -v xcodebuild &> /dev/null; then
        log_error "Xcode command line tools not found. Please install Xcode."
        exit 1
    fi
    
    # Check for M3 Pro or Apple Silicon
    ARCH_CHECK=$(uname -m)
    if [[ "$ARCH_CHECK" != "arm64" ]]; then
        log_warning "Not running on Apple Silicon. Build may not be optimized for M3 Pro."
    else
        log_success "Running on Apple Silicon ($ARCH_CHECK)"
    fi
    
    # Check macOS version
    MACOS_VERSION=$(sw_vers -productVersion)
    log_info "macOS version: $MACOS_VERSION"
    
    if [[ $(echo "$MACOS_VERSION 13.0" | tr " " "\n" | sort -V | head -n1) != "13.0" ]]; then
        log_warning "macOS version is below 13.0. Plugin may not work correctly."
    fi
}

# Clean build directory
clean_build() {
    log_info "Cleaning build directory..."
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
    fi
    mkdir -p "$BUILD_DIR"
}

# Build framework
build_framework() {
    log_info "Building TrackerControllerFramework..."
    
    xcodebuild \
        -project "${PROJECT_NAME}.xcodeproj" \
        -scheme "$SCHEME_FRAMEWORK" \
        -configuration "$CONFIGURATION" \
        -destination "platform=$PLATFORM,arch=$ARCH" \
        -derivedDataPath "$BUILD_DIR/DerivedData" \
        ARCHS="$ARCH" \
        VALID_ARCHS="$ARCH" \
        ONLY_ACTIVE_ARCH=YES \
        clean build
    
    if [ $? -eq 0 ]; then
        log_success "Framework built successfully"
    else
        log_error "Framework build failed"
        exit 1
    fi
}

# Build Audio Unit extension
build_audio_unit() {
    log_info "Building TrackerControllerAU extension..."
    
    xcodebuild \
        -project "${PROJECT_NAME}.xcodeproj" \
        -scheme "$SCHEME_AU" \
        -configuration "$CONFIGURATION" \
        -destination "platform=$PLATFORM,arch=$ARCH" \
        -derivedDataPath "$BUILD_DIR/DerivedData" \
        ARCHS="$ARCH" \
        VALID_ARCHS="$ARCH" \
        ONLY_ACTIVE_ARCH=YES \
        clean build
    
    if [ $? -eq 0 ]; then
        log_success "Audio Unit extension built successfully"
    else
        log_error "Audio Unit extension build failed"
        exit 1
    fi
}

# Build host application
build_host() {
    log_info "Building TrackerControllerHost application..."
    
    xcodebuild \
        -project "${PROJECT_NAME}.xcodeproj" \
        -scheme "$SCHEME_HOST" \
        -configuration "$CONFIGURATION" \
        -destination "platform=$PLATFORM,arch=$ARCH" \
        -derivedDataPath "$BUILD_DIR/DerivedData" \
        ARCHS="$ARCH" \
        VALID_ARCHS="$ARCH" \
        ONLY_ACTIVE_ARCH=YES \
        clean build
    
    if [ $? -eq 0 ]; then
        log_success "Host application built successfully"
    else
        log_error "Host application build failed"
        exit 1
    fi
}

# Code sign (for local testing)
code_sign() {
    log_info "Code signing applications..."
    
    # Find built products
    BUILT_PRODUCTS_DIR="$BUILD_DIR/DerivedData/Build/Products/$CONFIGURATION"
    
    if [ -d "$BUILT_PRODUCTS_DIR" ]; then
        # Sign framework
        if [ -d "$BUILT_PRODUCTS_DIR/TrackerControllerFramework.framework" ]; then
            codesign --force --sign - "$BUILT_PRODUCTS_DIR/TrackerControllerFramework.framework"
            log_success "Framework signed"
        fi
        
        # Sign host app
        if [ -d "$BUILT_PRODUCTS_DIR/TrackerControllerHost.app" ]; then
            codesign --force --sign - --deep "$BUILT_PRODUCTS_DIR/TrackerControllerHost.app"
            log_success "Host application signed"
        fi
        
        # Sign extension
        if [ -d "$BUILT_PRODUCTS_DIR/TrackerControllerHost.app/Contents/PlugIns/TrackerControllerAU.appex" ]; then
            codesign --force --sign - "$BUILT_PRODUCTS_DIR/TrackerControllerHost.app/Contents/PlugIns/TrackerControllerAU.appex"
            log_success "Audio Unit extension signed"
        fi
    else
        log_warning "Built products directory not found. Skipping code signing."
    fi
}

# Validate Audio Unit
validate_audio_unit() {
    log_info "Validating Audio Unit..."
    
    # Run the host app briefly to register the plugin
    BUILT_PRODUCTS_DIR="$BUILD_DIR/DerivedData/Build/Products/$CONFIGURATION"
    HOST_APP="$BUILT_PRODUCTS_DIR/TrackerControllerHost.app"
    
    if [ -d "$HOST_APP" ]; then
        log_info "Running host app to register Audio Unit..."
        timeout 10s open "$HOST_APP" || true
        sleep 2
        
        # Check if plugin is registered
        log_info "Checking plugin registration..."
        if pluginkit -m | grep -q "TrackerController"; then
            log_success "Audio Unit registered successfully"
        else
            log_warning "Audio Unit may not be registered properly"
        fi
        
        # Validate with auval
        log_info "Running auval validation..."
        if auval -v aumu TCTR POLY; then
            log_success "Audio Unit validation passed"
        else
            log_warning "Audio Unit validation failed or plugin not found"
        fi
    else
        log_error "Host application not found for validation"
    fi
}

# Copy to output directory
copy_output() {
    log_info "Copying build artifacts..."
    
    BUILT_PRODUCTS_DIR="$BUILD_DIR/DerivedData/Build/Products/$CONFIGURATION"
    OUTPUT_DIR="$BUILD_DIR/Output"
    
    mkdir -p "$OUTPUT_DIR"
    
    if [ -d "$BUILT_PRODUCTS_DIR/TrackerControllerHost.app" ]; then
        cp -R "$BUILT_PRODUCTS_DIR/TrackerControllerHost.app" "$OUTPUT_DIR/"
        log_success "Host application copied to $OUTPUT_DIR"
    fi
    
    if [ -d "$BUILT_PRODUCTS_DIR/TrackerControllerFramework.framework" ]; then
        cp -R "$BUILT_PRODUCTS_DIR/TrackerControllerFramework.framework" "$OUTPUT_DIR/"
        log_success "Framework copied to $OUTPUT_DIR"
    fi
}

# Main build process
main() {
    log_info "Starting build process for Tracker Controller Audio Unit Plugin"
    log_info "Target: Mac M3 Pro (Apple Silicon)"
    log_info "Configuration: $CONFIGURATION"
    
    check_prerequisites
    clean_build
    build_framework
    build_audio_unit
    build_host
    code_sign
    validate_audio_unit
    copy_output
    
    log_success "Build completed successfully!"
    log_info "Built products available in: $BUILD_DIR/Output"
    log_info ""
    log_info "To use the plugin:"
    log_info "1. Run the host app: open $BUILD_DIR/Output/TrackerControllerHost.app"
    log_info "2. Or load in your DAW as 'Polyend: Tracker Controller'"
    log_info ""
    log_info "For testing with auval:"
    log_info "auval -v aumu TCTR POLY"
}

# Handle command line arguments
case "${1:-}" in
    "clean")
        clean_build
        log_success "Build directory cleaned"
        ;;
    "framework")
        build_framework
        ;;
    "audiounit")
        build_audio_unit
        ;;
    "host")
        build_host
        ;;
    "validate")
        validate_audio_unit
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  (no args)  - Full build process"
        echo "  clean      - Clean build directory"
        echo "  framework  - Build framework only"
        echo "  audiounit  - Build Audio Unit extension only"
        echo "  host       - Build host application only"
        echo "  validate   - Validate Audio Unit"
        echo "  help       - Show this help"
        ;;
    *)
        main
        ;;
esac 