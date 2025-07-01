#!/bin/bash

# Develop Without Xcode Script
# Permette sviluppo e testing senza Xcode completo

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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
check_tools() {
    log_info "Checking available tools..."
    
    if command -v swift &> /dev/null; then
        SWIFT_VERSION=$(swift --version | head -n1)
        log_success "Swift found: $SWIFT_VERSION"
    else
        log_error "Swift not found. Install Xcode Command Line Tools."
        exit 1
    fi
    
    if command -v swiftc &> /dev/null; then
        log_success "Swift compiler found"
    else
        log_error "Swift compiler not found"
        exit 1
    fi
    
    if command -v git &> /dev/null; then
        log_success "Git found"
    else
        log_warning "Git not found - version control not available"
    fi
}

# Syntax check Swift files
check_syntax() {
    log_info "Checking Swift syntax..."
    
    local error_count=0
    
    for file in $(find TrackerControllerFramework -name "*.swift"); do
        echo -n "Checking $file... "
        if swiftc -typecheck "$file" 2>/dev/null; then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${RED}✗${NC}"
            swiftc -typecheck "$file"
            ((error_count++))
        fi
    done
    
    if [ $error_count -eq 0 ]; then
        log_success "All Swift files have valid syntax"
    else
        log_error "$error_count files have syntax errors"
        return 1
    fi
}

# Build Swift framework (limited)
build_framework_swift() {
    log_info "Building Swift framework (limited functionality)..."
    
    mkdir -p build/swift
    
    # Compile Swift files individually
    local swift_files=(
        "TrackerControllerFramework/TrackerControllerViewModel.swift"
        "TrackerControllerFramework/ErrorHandler.swift"
    )
    
    for file in "${swift_files[@]}"; do
        if [ -f "$file" ]; then
            echo "Compiling $file..."
            swiftc -c "$file" -o "build/swift/$(basename "$file" .swift).o" || {
                log_error "Failed to compile $file"
                return 1
            }
        fi
    done
    
    log_success "Swift compilation completed (partial)"
}

# Lint code
lint_code() {
    log_info "Running code analysis..."
    
    # Check for common issues
    local issues=0
    
    # Check for force unwraps
    if grep -r "!" TrackerControllerFramework --include="*.swift" | grep -v "//"; then
        log_warning "Found force unwraps (!) - consider using safe unwrapping"
        ((issues++))
    fi
    
    # Check for print statements
    if grep -r "print(" TrackerControllerFramework --include="*.swift"; then
        log_warning "Found print statements - use logging instead"
        ((issues++))
    fi
    
    # Check for TODO/FIXME
    if grep -r -E "(TODO|FIXME)" TrackerControllerFramework --include="*.swift"; then
        log_info "Found TODO/FIXME comments"
    fi
    
    if [ $issues -eq 0 ]; then
        log_success "Code analysis completed - no major issues found"
    else
        log_warning "Code analysis found $issues potential issues"
    fi
}

# Generate documentation
generate_docs() {
    log_info "Generating documentation..."
    
    mkdir -p build/docs
    
    # Extract public APIs
    grep -r "public " TrackerControllerFramework --include="*.swift" > build/docs/public_api.txt || true
    grep -r "class\|struct\|enum\|protocol" TrackerControllerFramework --include="*.swift" > build/docs/types.txt || true
    
    log_success "Documentation extracted to build/docs/"
}

# Test MIDI functionality (if possible)
test_midi() {
    log_info "Testing MIDI functionality..."
    
    # Check MIDI devices
    if command -v system_profiler &> /dev/null; then
        log_info "Available MIDI devices:"
        system_profiler SPAudioDataType | grep -A 5 -i midi || log_warning "No MIDI devices found"
    fi
    
    # Check for Tracker Mini
    if system_profiler SPUSBDataType | grep -i "polyend\|tracker" &> /dev/null; then
        log_success "Polyend device detected via USB"
    else
        log_warning "No Polyend device detected"
    fi
}

# Setup development environment
setup_dev_env() {
    log_info "Setting up development environment..."
    
    # Create necessary directories
    mkdir -p build/{swift,docs,logs}
    
    # Setup git hooks (if git available)
    if command -v git &> /dev/null && [ -d .git ]; then
        cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
echo "Running pre-commit checks..."
./develop_without_xcode.sh syntax
EOF
        chmod +x .git/hooks/pre-commit
        log_success "Git pre-commit hook installed"
    fi
    
    # Create development config
    cat > build/dev_config.json << EOF
{
    "project": "TrackerController",
    "version": "1.1.0",
    "development_mode": true,
    "xcode_available": false,
    "last_check": "$(date)"
}
EOF
    
    log_success "Development environment setup completed"
}

# Push to GitHub for cloud build
push_for_build() {
    if ! command -v git &> /dev/null; then
        log_error "Git not available - cannot push for cloud build"
        return 1
    fi
    
    if [ ! -d .git ]; then
        log_error "Not a git repository - initialize with 'git init'"
        return 1
    fi
    
    log_info "Preparing for cloud build..."
    
    # Check if there are changes
    if git diff --quiet && git diff --staged --quiet; then
        log_warning "No changes to commit"
    else
        log_info "Committing changes..."
        git add .
        git commit -m "Update for cloud build - $(date)"
    fi
    
    # Check if remote exists
    if git remote get-url origin &> /dev/null; then
        log_info "Pushing to origin for GitHub Actions build..."
        git push origin main || git push origin master || {
            log_error "Failed to push - check remote configuration"
            return 1
        }
        log_success "Pushed to GitHub - check Actions tab for build status"
    else
        log_error "No git remote configured. Add with:"
        echo "git remote add origin https://github.com/USERNAME/REPO.git"
    fi
}

# Show alternatives
show_alternatives() {
    log_info "Alternatives to local Xcode installation:"
    echo ""
    echo "1. 🌐 GitHub Actions (Recommended)"
    echo "   - Push code to GitHub"
    echo "   - Automatic build in cloud"
    echo "   - Download compiled plugin"
    echo ""
    echo "2. 💿 External Drive"
    echo "   - Install Xcode on USB-C drive"
    echo "   - Slower but functional"
    echo ""
    echo "3. 🤝 Collaboration"
    echo "   - Share code with Xcode user"
    echo "   - Remote development"
    echo ""
    echo "4. ☁️ Xcode Cloud"
    echo "   - Apple's cloud build service"
    echo "   - Requires Apple Developer account"
    echo ""
}

# Main menu
main() {
    case "${1:-}" in
        "syntax")
            check_syntax
            ;;
        "build")
            build_framework_swift
            ;;
        "lint")
            lint_code
            ;;
        "docs")
            generate_docs
            ;;
        "midi")
            test_midi
            ;;
        "setup")
            setup_dev_env
            ;;
        "push")
            push_for_build
            ;;
        "alternatives")
            show_alternatives
            ;;
        "all")
            check_tools
            check_syntax
            lint_code
            generate_docs
            test_midi
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  syntax       - Check Swift syntax"
            echo "  build        - Build Swift framework (limited)"
            echo "  lint         - Run code analysis"
            echo "  docs         - Generate documentation"
            echo "  midi         - Test MIDI functionality"
            echo "  setup        - Setup development environment"
            echo "  push         - Push to GitHub for cloud build"
            echo "  alternatives - Show Xcode alternatives"
            echo "  all          - Run all checks"
            echo "  help         - Show this help"
            ;;
        *)
            log_info "Tracker Controller - Development Without Xcode"
            echo ""
            show_alternatives
            echo ""
            echo "Run '$0 help' for available commands"
            echo "Run '$0 all' to run all available checks"
            ;;
    esac
}

# Check tools first
check_tools

# Run main function
main "$@" 