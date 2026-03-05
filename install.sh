#!/usr/bin/env bash
# =============================================================================
# omsenjalia/dotfiles — Arch Linux install script
# https://github.com/omsenjalia/dotfiles
#
# Run as a regular user with sudo access — NOT as root.
# Safe to re-run (idempotent).
#
# Usage:
#   git clone https://github.com/omsenjalia/dotfiles ~/dotfiles
#   cd ~/dotfiles
#   bash install.sh
# =============================================================================
set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()      { echo -e "${GREEN}[ OK ]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERR ]${NC}  $*" >&2; exit 1; }
section() { echo -e "\n${BOLD}${GREEN}━━━  $*  ━━━${NC}"; }

# ── Safety ───────────────────────────────────────────────────────────────────
[[ $EUID -eq 0 ]] && error "Do NOT run as root. Run as your regular user: bash install.sh"

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_FILE="$DOTFILES_DIR/packages.txt"

[[ -f "$PACKAGES_FILE" ]] || error "packages.txt not found in $DOTFILES_DIR"

info "Dotfiles dir : $DOTFILES_DIR"
info "Running as   : $(whoami)  →  $HOME"

# ── Helpers ──────────────────────────────────────────────────────────────────

# Parse lines between [pacman] and [aur], split on commas, strip whitespace
parse_pacman_pkgs() {
    awk '/^\[pacman\]/{f=1;next} /^\[/{f=0} f' "$PACKAGES_FILE" \
        | grep -v '^\s*#' \
        | tr ',' '\n' \
        | sed 's/[[:space:]]//g' \
        | grep -v '^$'
}

# Parse lines after [aur]
parse_aur_pkgs() {
    awk '/^\[aur\]/{f=1;next} /^\[/{f=0} f' "$PACKAGES_FILE" \
        | grep -v '^\s*#' \
        | tr ',' '\n' \
        | sed 's/[[:space:]]//g' \
        | grep -v '^$'
}

# ═════════════════════════════════════════════════════════════════════════════
# 1. Bootstrap
# ═════════════════════════════════════════════════════════════════════════════
section "Bootstrap — base-devel, git, stow"
sudo pacman -Syu --needed --noconfirm base-devel git stow
ok "Bootstrap ready"

# ═════════════════════════════════════════════════════════════════════════════
# 2. yay (AUR helper)
# ═════════════════════════════════════════════════════════════════════════════
section "AUR helper — yay"
if ! command -v yay &>/dev/null; then
    info "Building yay from AUR…"
    _TMP=$(mktemp -d)
    git clone --depth=1 https://aur.archlinux.org/yay.git "$_TMP/yay"
    ( cd "$_TMP/yay" && makepkg -si --noconfirm )
    rm -rf "$_TMP"
    ok "yay installed"
else
    ok "yay already present  ($(yay --version | head -1))"
fi

# ═════════════════════════════════════════════════════════════════════════════
# 3. pacman packages
# ═════════════════════════════════════════════════════════════════════════════
section "pacman packages"
mapfile -t PACMAN_PKGS < <(parse_pacman_pkgs)

if [[ ${#PACMAN_PKGS[@]} -gt 0 ]]; then
    info "Installing ${#PACMAN_PKGS[@]} pacman packages…"
    sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"
    ok "pacman packages done"
else
    warn "No pacman packages parsed — check packages.txt"
fi

# ═════════════════════════════════════════════════════════════════════════════
# 4. AUR packages
# ═════════════════════════════════════════════════════════════════════════════
section "AUR packages"
mapfile -t AUR_PKGS < <(parse_aur_pkgs)

if [[ ${#AUR_PKGS[@]} -gt 0 ]]; then
    info "Installing ${#AUR_PKGS[@]} AUR packages…"
    yay -S --needed --noconfirm "${AUR_PKGS[@]}"
    ok "AUR packages done"
else
    warn "No AUR packages parsed — check packages.txt"
fi

# ═════════════════════════════════════════════════════════════════════════════
# 5. Stow dotfiles
# ═════════════════════════════════════════════════════════════════════════════
section "Stowing dotfiles → $HOME"

# Files at repo root that should NOT be linked into $HOME
STOW_IGNORE=(
    'install\.sh'
    'packages\.txt'
    'README\.md'
    '\.sync-ignore'
    '\.last-synced-release'
    '\.github'
)

IGNORE_FLAGS=()
for pattern in "${STOW_IGNORE[@]}"; do
    IGNORE_FLAGS+=(--ignore="$pattern")
done

PARENT_DIR="$(dirname "$DOTFILES_DIR")"
REPO_NAME="$(basename "$DOTFILES_DIR")"

# Detect conflicts before touching anything
CONFLICTS=$(stow --no-folding -n -t "$HOME" "${IGNORE_FLAGS[@]}" -d "$PARENT_DIR" "$REPO_NAME" 2>&1 | grep 'CONFLICT\|existing target' || true)

if [[ -n "$CONFLICTS" ]]; then
    BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    warn "Conflicts detected — backing up to $BACKUP_DIR"
    echo "$CONFLICTS" | grep -oP '(?<=: ).*$' | while read -r target; do
        src="$HOME/$target"
        [[ -e "$src" && ! -L "$src" ]] && mv -v "$src" "$BACKUP_DIR/"
    done
fi

stow --no-folding -v -R -t "$HOME" "${IGNORE_FLAGS[@]}" -d "$PARENT_DIR" "$REPO_NAME"
ok "Dotfiles stowed"

# ═════════════════════════════════════════════════════════════════════════════
# 6. System services
# ═════════════════════════════════════════════════════════════════════════════
section "System services"

enable_system_service() {
    local unit="$1"
    if systemctl list-unit-files "$unit" &>/dev/null; then
        sudo systemctl enable --now "$unit" && ok "Enabled $unit" || warn "Could not enable $unit"
    else
        warn "$unit not found — skipping"
    fi
}

enable_system_service NetworkManager.service
enable_system_service bluetooth.service
enable_system_service tailscaled.service

# ═════════════════════════════════════════════════════════════════════════════
# 7. User services
# ═════════════════════════════════════════════════════════════════════════════
section "User services"

enable_user_service() {
    local unit="$1"
    if [[ -d "/run/user/$(id -u)" ]]; then
        systemctl --user enable --now "$unit" && ok "Enabled user:$unit" || warn "Could not enable user:$unit"
    else
        sudo loginctl enable-linger "$(whoami)"
        warn "$unit — no live user session yet; will start on next login (linger enabled)"
    fi
}

enable_user_service pipewire.service
enable_user_service pipewire-pulse.service
enable_user_service wireplumber.service

# ═════════════════════════════════════════════════════════════════════════════
# 8. Default shell → fish
# ═════════════════════════════════════════════════════════════════════════════
section "Default shell"

FISH_BIN="$(command -v fish 2>/dev/null || true)"
if [[ -z "$FISH_BIN" ]]; then
    warn "fish not found in PATH — skipping shell change"
elif [[ "$SHELL" == "$FISH_BIN" ]]; then
    ok "fish is already the default shell"
else
    grep -qxF "$FISH_BIN" /etc/shells || echo "$FISH_BIN" | sudo tee -a /etc/shells >/dev/null
    chsh -s "$FISH_BIN"
    ok "Default shell → fish ($FISH_BIN)"
fi

# ═════════════════════════════════════════════════════════════════════════════
# 9. GitHub CLI extensions
# ═════════════════════════════════════════════════════════════════════════════
section "gh extensions"

if command -v gh &>/dev/null; then
    if gh auth status &>/dev/null 2>&1; then
        gh extension install nicholasgasior/gh-eco 2>/dev/null \
            && ok "gh-eco installed" \
            || warn "gh-eco already present or failed"
    else
        warn "gh not authenticated — skipping extensions (run: gh auth login)"
    fi
else
    warn "gh not in PATH — skipping"
fi

# ═════════════════════════════════════════════════════════════════════════════
# 10. Manual steps summary
# ═════════════════════════════════════════════════════════════════════════════
echo ""
printf '\033[1;33m╔══════════════════════════════════════════════════════════════════╗\n'
printf '║           MANUAL STEPS REQUIRED — complete these now            ║\n'
printf '╚══════════════════════════════════════════════════════════════════╝\033[0m\n'

cat <<'MANUAL'

 1.  Git / jj email
     ───────────────
     Edit ~/.config/git/config        → set your email
     Edit ~/.config/jj/config.toml   → set your email

 2.  SSH key
     ────────
     ssh-keygen -t ed25519 -C "your@email.com"
     # Add ~/.ssh/id_ed25519.pub to GitHub (Authentication + Signing key):
     # https://github.com/settings/ssh/new

 3.  SSH allowed_signers  (git SSH commit signing)
     ───────────────────────────────────────────────
     echo "your@email.com namespaces=\"git\" $(cat ~/.ssh/id_ed25519.pub)" \
         > ~/.ssh/allowed_signers

 4.  Berkeley Mono font  ← paid font
     ─────────────────────────────────
     Purchase: https://berkeleygraphics.com/typefaces/berkeley-mono/
     Install TTF/OTF files → ~/.local/share/fonts/
     Run: fc-cache -fv
     (Ghostty and GTK fall back to system monospace until then)

 5.  Hyprland monitor config
     ─────────────────────────
     hyprctl monitors
     Edit: ~/.config/hypr/hyprland.conf  — update the monitor = line(s)

 6.  Tailscale
     ──────────
     sudo tailscale up

 7.  Atuin sync  (optional)
     ────────────────────────
     Edit ~/.config/atuin/config.toml — uncomment/set sync_address
     atuin login && atuin sync

 8.  Neovim (izvim)
     ─────────────────
     git clone https://github.com/isabelroses/nvim ~/.config/nvim
     nvim   # plugins install automatically via lazy.nvim on first launch

 9.  MPV scripts
     ────────────
     yay -S mpv-modernz-git mpv-thumbfast-git mpv-sponsorblock-git mpv-mpris

10.  Spicetify  (after first Spotify launch)
     ─────────────────────────────────────────
     spicetify backup apply
     spicetify config current_theme catppuccin color_scheme mocha
     spicetify apply

11.  Discord Moonlight
     ──────────────────
     https://moonlight-mod.github.io

12.  WakaTime API key
     ─────────────────
     wakatime --settings
     # Key: https://wakatime.com/settings/api-key

13.  Secrets / sensitive env vars
     ─────────────────────────────
     Upstream uses sops-nix — on Arch use pass or age:
       sudo pacman -S pass && pass init <your-gpg-id>

14.  gh auth
     ───────
     gh auth login

MANUAL

echo -e "\033[1;32mAll done!\033[0m  Reboot (or log out/in) then launch Hyprland."
echo ""
