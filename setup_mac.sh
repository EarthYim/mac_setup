#!/usr/bin/env zsh
set -e

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo "${GREEN}[INFO]${NC}  $1"; }
warn()    { echo "${YELLOW}[WARN]${NC}  $1"; }
error()   { echo "${RED}[ERROR]${NC} $1"; exit 1; }

# ── Guard: Apple Silicon ──────────────────────────────────────────────────────
[[ "$(uname -m)" == "arm64" ]] || error "This script is intended for Apple Silicon (arm64) Macs."

# ── 1. Apple Command Line Tools ───────────────────────────────────────────────
info "Checking Apple Command Line Tools..."
if xcode-select -p &>/dev/null; then
  info "Command Line Tools already installed — skipping."
else
  info "Installing Command Line Tools (a dialog may appear)..."
  xcode-select --install
  # Wait until the tools are actually available before continuing
  until xcode-select -p &>/dev/null; do
    sleep 5
  done
  info "Command Line Tools installed."
fi

# ── 2. Homebrew ───────────────────────────────────────────────────────────────
info "Checking Homebrew..."
if command -v brew &>/dev/null; then
  info "Homebrew already installed — updating."
  brew update
else
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  info "Homebrew installed."
fi

# Ensure brew is on PATH for this script and all future shell sessions
eval "$(/opt/homebrew/bin/brew shellenv)"
if ! grep -q 'brew shellenv' ~/.zprofile 2>/dev/null; then
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  info "Homebrew added to PATH in ~/.zprofile."
fi

# ── 3. oh-my-zsh ─────────────────────────────────────────────────────────────
info "Checking oh-my-zsh..."
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  info "oh-my-zsh already installed — skipping."
else
  info "Installing oh-my-zsh..."
  # RUNZSH=no prevents the installer from switching shells mid-script
  RUNZSH=no CHSH=no \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  info "oh-my-zsh installed."
fi

# ── 4. Set agnoster theme ─────────────────────────────────────────────────────
info "Setting ZSH_THEME to agnoster in ~/.zshrc..."
if grep -q '^ZSH_THEME=' ~/.zshrc; then
  sed -i '' 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' ~/.zshrc
else
  echo 'ZSH_THEME="agnoster"' >> ~/.zshrc
fi
info "Theme set to agnoster."

# ── 5. vimrc ─────────────────────────────────────────────────────────────────
info "Installing .vimrc..."
SCRIPT_DIR="${0:A:h}"
if [[ -f "$SCRIPT_DIR/.vimrc" ]]; then
  cp "$SCRIPT_DIR/.vimrc" "$HOME/.vimrc"
  info ".vimrc copied to ~/.vimrc."
else
  warn ".vimrc not found next to this script — writing defaults directly."
  cat > "$HOME/.vimrc" <<'EOF'
syntax on
filetype plugin indent on

set autoindent
set smartindent
set expandtab
set tabstop=4
set shiftwidth=4
EOF
  info ".vimrc written to ~/.vimrc."
fi

# ── 6. Cask applications ──────────────────────────────────────────────────────
CASKS=(
  linearmouse
  warp
  rectangle
  alt-tab
  visual-studio-code
  alfred
  docker
)

info "Installing cask applications..."
for cask in "${CASKS[@]}"; do
  if brew list --cask "$cask" &>/dev/null; then
    info "$cask already installed — skipping."
  else
    info "Installing $cask..."
    brew install --cask "$cask"
  fi
done

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
info "Setup complete! Open a new terminal (or run: source ~/.zprofile && source ~/.zshrc) to apply changes."
