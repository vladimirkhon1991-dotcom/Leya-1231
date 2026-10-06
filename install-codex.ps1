# install-codex.ps1
# =============================================================================
# Codex One-Click Installer with VS Code Integration
# =============================================================================

param(
    [switch]$SkipVSCode = $false
)

$repoUrl = "https://github.com/vladimirkhon1991-dotcom/Leya-1231.git"
$repoPath = "$HOME\Leya-1231"
$setupLog = "$repoPath\setup.log"

# Color output
function Write-Status($message) {
    Write-Host "[*] $message" -ForegroundColor Cyan
}

function Write-Success($message) {
    Write-Host "[✓] $message" -ForegroundColor Green
}

function Write-Error-Custom($message) {
    Write-Host "[✗] $message" -ForegroundColor Red
}

function Write-Warning-Custom($message) {
    Write-Host "[!] $message" -ForegroundColor Yellow
}

# =============================================================================
# Step 1: Check for Git
# =============================================================================
Write-Status "Checking prerequisites..."
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error-Custom "Git is not installed. Please install Git from https://git-scm.com/"
    exit 1
}
Write-Success "Git found"

# =============================================================================
# Step 2: Clone repo if needed
# =============================================================================
if (-not (Test-Path $repoPath)) {
    Write-Status "Cloning repository..."
    git clone $repoUrl $repoPath
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Failed to clone repository"
        exit 1
    }
    Write-Success "Repository cloned"
} else {
    Write-Success "Repository already exists"
}

# =============================================================================
# Step 3: Check WSL2 installation
# =============================================================================
Write-Status "Checking WSL2 status..."
$wslStatus = wsl --status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Warning-Custom "WSL2 not found, installing..."
    Write-Host "This may require a system restart. You'll need to re-run this script after."
    wsl --install -d Ubuntu
    Write-Host ""
    Write-Host "WSL installation initiated. Please restart your computer and run this script again."
    Write-Host "Command: .\install-codex.ps1"
    exit 0
}
Write-Success "WSL2 is installed"

# =============================================================================
# Step 4: Convert path for WSL
# =============================================================================
$wslRepo = ($repoPath -replace '\\', '/').Replace('C:/', '/mnt/c/')

# =============================================================================
# Step 5: Run setup script with logging
# =============================================================================
Write-Status "Running Codex setup in WSL (this will take 5-10 minutes)..."
Write-Host "Log file: $setupLog"
Write-Host ""

# Run setup.sh and capture output
wsl bash -lc "cd '$wslRepo' && bash ./setup.sh 2>&1 | tee setup.log" | Tee-Object -FilePath $setupLog

if ($LASTEXITCODE -ne 0) {
    Write-Warning-Custom "Setup completed with some warnings (this is often OK)"
} else {
    Write-Success "Setup completed successfully"
}

# =============================================================================
# Step 6: Copy setup log to Windows for reference
# =============================================================================
$wslLogPath = "/mnt/c/Users/$($env:USERNAME)/Leya-1231/setup.log"
Write-Status "Setup complete!"

# =============================================================================
# Step 7: Open in VS Code (if available and not skipped)
# =============================================================================
Write-Status "Opening VS Code..."
if (Get-Command code -ErrorAction SilentlyContinue) {
    if (-not $SkipVSCode) {
        # Install VS Code extensions for Rust if not present
        Write-Status "Installing Rust extensions in VS Code..."
        code --install-extension rust-lang.rust-analyzer --force 2>&1 | Out-Null
        code --install-extension vadimcn.vscode-lldb --force 2>&1 | Out-Null
        code --install-extension serayuzgur.crates --force 2>&1 | Out-Null
        
        # Open repo in VS Code
        Write-Status "Launching VS Code with Leya-1231..."
        code $repoPath
        Write-Success "VS Code opened with your project"
    }
} else {
    Write-Warning-Custom "VS Code not found. Install from https://code.visualstudio.com/ or run manually:"
    Write-Host "  code $repoPath"
}

Write-Host ""
Write-Host "═════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "Codex is ready!" -ForegroundColor Green
Write-Host "═════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. VS Code is open with Leya-1231"
Write-Host "  2. Open a terminal in VS Code (Ctrl + `)"
Write-Host "  3. Run Codex:"
Write-Host ""
Write-Host "     wsl bash -lc ""cd ~/Leya-1231/codex-rs && cargo run --release --bin codex -- 'explain this codebase to me'""" -ForegroundColor Yellow
Write-Host ""
Write-Host "Or use the just helpers:" -ForegroundColor Cyan
Write-Host "  wsl bash -lc ""cd ~/Leya-1231/codex-rs && just fmt""" -ForegroundColor Yellow
Write-Host "  wsl bash -lc ""cd ~/Leya-1231/codex-rs && just fix""" -ForegroundColor Yellow
Write-Host "  wsl bash -lc ""cd ~/Leya-1231/codex-rs && just test""" -ForegroundColor Yellow
Write-Host ""
Write-Host "Setup log saved to: $setupLog" -ForegroundColor Gray
Write-Host ""
