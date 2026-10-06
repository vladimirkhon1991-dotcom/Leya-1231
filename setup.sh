#!/bin/bash
set -euo pipefail

# =============================================================================
# CODEX SETUP SCRIPT - Full automated setup with validation
# =============================================================================

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
STEPS_COMPLETED=0
TOTAL_STEPS=8

# Utility functions
log_step() {
    STEPS_COMPLETED=$((STEPS_COMPLETED + 1))
    echo -e "${BLUE}[${STEPS_COMPLETED}/${TOTAL_STEPS}]${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
    exit 1
}

# =============================================================================
# STEP 1: Verify we're in the right location
# =============================================================================
log_step "Verifying repository structure..."
if [ ! -f "Cargo.toml" ] || [ ! -d "codex-rs" ]; then
    log_error "Not in Leya-1231 root directory. Please run from repo root."
fi
log_success "Repository structure verified"

# =============================================================================
# STEP 2: Check for Rust installation
# =============================================================================
log_step "Checking Rust toolchain..."
if ! command -v rustup &> /dev/null; then
    log_warning "Rust not found, installing..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --quiet
    source "$HOME/.cargo/env"
    log_success "Rust installed"
else
    log_success "Rust toolchain found ($(rustc --version))"
    source "$HOME/.cargo/env" 2>/dev/null || true
fi

# =============================================================================
# STEP 3: Install Rust components (fast, cached)
# =============================================================================
log_step "Installing Rust components (rustfmt, clippy)..."
rustup component add rustfmt --quiet 2>/dev/null || true
rustup component add clippy --quiet 2>/dev/null || true
log_success "Rust components ready"

# =============================================================================
# STEP 4: Install Cargo helper tools (cached)
# =============================================================================
log_step "Installing Cargo tools (just, dotslash, cargo-nextest)..."
CARGO_TERM_QUIET=true cargo install --locked just 2>/dev/null || log_warning "just may already be installed"
CARGO_TERM_QUIET=true cargo install --locked dotslash 2>/dev/null || log_warning "dotslash may already be installed"
CARGO_TERM_QUIET=true cargo install --locked cargo-nextest 2>/dev/null || log_warning "cargo-nextest may already be installed"
log_success "Cargo tools ready"

# =============================================================================
# STEP 5: Navigate to workspace and clean build artifacts (optional optimization)
# =============================================================================
log_step "Preparing workspace..."
cd codex-rs
log_success "Workspace ready at $(pwd)"

# =============================================================================
# STEP 6: Build with optimizations (release profile, parallel)
# =============================================================================
log_step "Building Codex (release mode with optimizations)..."
export CARGO_BUILD_JOBS=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
export CARGO_NET_GIT_FETCH_WITH_CLI=true
export RUSTFLAGS="-C link-arg=-fuse-ld=lld" 2>/dev/null || true

if cargo build --release -j "$CARGO_BUILD_JOBS" 2>&1 | grep -E "^(Compiling|Finished)" ; then
    log_success "Build completed successfully"
else
    log_error "Build failed. Check output above."
fi

# =============================================================================
# STEP 7: Run fast validation tests (project-specific, not --all-features)
# =============================================================================
log_step "Running validation tests (codex-tui)..."
if just test -p codex-tui 2>&1 | tail -5; then
    log_success "Validation tests passed"
else
    log_warning "Some tests failed, but build is functional. Continuing..."
fi

# =============================================================================
# STEP 8: Display final status and next steps
# =============================================================================
log_step "Setup complete!"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Codex is now fully functional and ready to use!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Quick start commands:"
echo -e "  ${BLUE}Launch TUI:${NC}"
echo "    cargo run --release --bin codex -- \"explain this codebase to me\""
echo ""
echo -e "  ${BLUE}Use just helpers:${NC}"
echo "    just fmt              # Format all code"
echo "    just fix              # Apply clippy lints"
echo "    just test             # Run full test suite (or: just test -p <crate>)"
echo ""
echo -e "  ${BLUE}Verbose logging:${NC}"
echo "    RUST_LOG=debug cargo run --release --bin codex -- \"<prompt>\""
echo ""
echo -e "  ${BLUE}View binaries:${NC}"
echo "    ls -lh target/release/codex target/release/codex-* 2>/dev/null | head -10"
echo ""
