#!/bin/bash
set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Step 1: Check if we're in the right directory
if [ ! -d "codex-rs" ]; then
    log_error "codex-rs directory not found. Run this from the repository root."
    exit 1
fi

cd codex-rs

log_info "Starting Codex setup..."

# Step 2: Install Rust if not already installed
if ! command -v rustup &> /dev/null; then
    log_info "Installing Rust toolchain..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    log_success "Rust installed"
else
    log_info "Rust already installed"
    source "$HOME/.cargo/env"
fi

# Step 3: Install Rust components
log_info "Installing Rust components..."
rustup component add rustfmt 2>/dev/null || log_info "rustfmt already installed"
rustup component add clippy 2>/dev/null || log_info "clippy already installed"
log_success "Rust components ready"

# Step 4: Install helper tools
log_info "Installing Cargo tools (just, dotslash, cargo-nextest)..."
cargo install --locked just 2>/dev/null || log_info "just already installed"
cargo install --locked dotslash 2>/dev/null || log_info "dotslash already installed"
cargo install --locked cargo-nextest 2>/dev/null || log_info "cargo-nextest already installed"
log_success "Cargo tools installed"

# Step 5: Build with optimizations
log_info "Building Codex (this may take 5-10 minutes)..."
CARGO_NET_GIT_FETCH_WITH_CLI=true cargo build --release
log_success "Build complete"

# Step 6: Verify build with tests
log_info "Running tests to verify installation..."
just test
log_success "All tests passed"

# Step 7: Show next steps
echo ""
log_success "Codex is now fully functional!"
echo ""
echo "Next steps:"
echo "  • Launch the TUI:"
echo "    cargo run --bin codex -- \"explain this codebase to me\""
echo ""
echo "  • Use just helpers:"
echo "    just fmt          # Format code"
echo "    just fix          # Run lints"
echo "    just test -p <crate-name>  # Test specific crate"
echo ""
echo "  • Enable verbose logging:"
echo "    RUST_LOG=debug cargo run --bin codex -- ..."
echo ""
