# dotfiles

Personal Arch Linux dotfiles — a port of [isabelroses/dotfiles](https://github.com/isabelroses/dotfiles) (NixOS) to Arch + stow.

**Stack:** Hyprland · fish · Ghostty · Neovim · Catppuccin Mocha/pink

---

## Prerequisites

- Fresh Arch Linux install with internet access
- A regular user account with `sudo` rights
- `git` (install with `sudo pacman -S git` if not present)

---

## Install

```bash
git clone https://github.com/omsenjalia/dotfiles ~/dotfiles
cd ~/dotfiles
bash install.sh
```

> **Do not run as root.** The script will error if you do.

---

## What the script does

| Step | What happens |
|------|-------------|
| 1 | Updates the system and installs `base-devel`, `git`, `stow` |
| 2 | Builds and installs `yay` from the AUR if not already present |
| 3 | Installs all packages listed under `[pacman]` in `packages.txt` |
| 4 | Installs all packages listed under `[aur]` in `packages.txt` via yay |
| 5 | Symlinks all dotfiles into `$HOME` via `stow` (conflicting files are backed up to `~/.dotfiles-backup-<timestamp>`) |
| 6 | Enables system services: `NetworkManager`, `bluetooth`, `tailscaled` |
| 7 | Enables user services: `pipewire`, `pipewire-pulse`, `wireplumber` |
| 8 | Sets `fish` as the default shell via `chsh` |
| 9 | Installs the `gh-eco` GitHub CLI extension (requires `gh auth login` first) |
| 10 | Prints a checklist of manual steps |

---

## Manual steps (do these after the script finishes)

### 1 · Git & jj email

```bash
# ~/.config/git/config
[user]
    email = you@example.com

# ~/.config/jj/config.toml
[user]
email = "you@example.com"
```

### 2 · SSH key

```bash
ssh-keygen -t ed25519 -C "you@example.com"
cat ~/.ssh/id_ed25519.pub   # add to GitHub → Settings → SSH keys
                            # add once as Authentication key, once as Signing key
```

### 3 · SSH allowed\_signers (git commit signing)

```bash
echo 'you@example.com namespaces="git" '"$(cat ~/.ssh/id_ed25519.pub)" \
    > ~/.ssh/allowed_signers
```

### 4 · Berkeley Mono (paid font)

The config references **Berkeley Mono** everywhere. Until it's installed, Ghostty and GTK fall back to the system monospace font.

1. Purchase at <https://berkeleygraphics.com/typefaces/berkeley-mono/>
2. Copy the TTF/OTF files to `~/.local/share/fonts/`
3. Run `fc-cache -fv`

### 5 · Hyprland monitors

```bash
hyprctl monitors          # find your output names & resolutions
```

Then edit `~/.config/hypr/hyprland.conf` and replace the placeholder line:

```ini
# before
monitor = , preferred, auto, 1

# after (example)
monitor = DP-1, 2560x1440@144, 0x0, 1
monitor = HDMI-A-1, 1920x1080@60, 2560x0, 1
```

### 6 · Tailscale

```bash
sudo tailscale up
```

### 7 · Atuin sync (optional)

Edit `~/.config/atuin/config.toml` and uncomment `sync_address` (use `https://api.atuin.sh` for the hosted service or your self-hosted URL), then:

```bash
atuin login
atuin sync
```

### 8 · Neovim

The upstream config is [isabelroses/nvim](https://github.com/isabelroses/nvim):

```bash
git clone https://github.com/isabelroses/nvim ~/.config/nvim
nvim    # lazy.nvim bootstraps and installs plugins on first launch
```

### 9 · MPV scripts

Not all MPV scripts have stable AUR packages — install them manually:

```bash
yay -S mpv-modernz-git mpv-thumbfast-git mpv-sponsorblock-git mpv-mpris
```

### 10 · Spicetify

Launch Spotify once, then:

```bash
spicetify backup apply
spicetify config current_theme catppuccin color_scheme mocha
spicetify apply
```

### 11 · Discord Moonlight

Install manually from <https://moonlight-mod.github.io>.

### 12 · WakaTime

```bash
wakatime --settings    # paste your API key from wakatime.com/settings/api-key
```

### 13 · Secrets & sensitive env vars

Upstream uses `sops-nix`. On Arch, use `pass` or `age`:

```bash
sudo pacman -S pass
pass init <your-gpg-id>
```

### 14 · GitHub CLI

```bash
gh auth login
```

---

## Customisation

### Adding or removing packages

Edit `packages.txt`. The format is:

```
[pacman]
package1, package2,
package3

[aur]
aur-pkg1, aur-pkg2
```

Re-run `bash install.sh` — it's idempotent, so already-installed packages are skipped.

### Changing the git username

```bash
# ~/.config/git/config
[user]
    name = yourname
```

### Changing the Hyprland modifier key

```bash
# ~/.config/hypr/hyprland.conf
$mod = SUPER    # change to e.g. ALT
```

### Changing the Catppuccin accent

The accent colour (pink) is referenced in:

- `~/.config/hypr/hyprland.conf` — border colours
- `~/.config/gtk-*/settings.ini` — GTK theme name
- `~/.config/fish/conf.d/20-env.fish` — `KVANTUM_THEME`

Change `pink` / `mocha-pink` to any [Catppuccin accent](https://github.com/catppuccin/catppuccin#-palette) in those files.

---

## Directory structure

```
~/dotfiles/
├── .config/
│   ├── atuin/          config.toml
│   ├── bat/            config
│   ├── direnv/         direnvrc
│   ├── fish/           config.fish  conf.d/  functions/
│   ├── gh/             config.yml
│   ├── ghostty/        config
│   ├── git/            config  ignore
│   ├── gtk-2.0/        gtkrc
│   ├── gtk-3.0/        settings.ini
│   ├── gtk-4.0/        settings.ini
│   ├── hypr/           hyprland.conf
│   ├── jj/             config.toml
│   ├── kvantum/
│   ├── lazygit/        config.yml
│   ├── mpv/            mpv.conf  input.conf  script-opts/
│   ├── pipewire/       pipewire.conf.d/99-input-denoising.conf
│   ├── qt/  qt5ct/  qt6ct/
│   ├── ripgrep/        ripgreprc
│   ├── starship.toml
│   ├── wezterm/
│   ├── zk/             config.toml
│   └── …
├── .ssh/
│   └── config
├── .bashrc
├── .bash_profile
├── .profile
├── .github/
│   └── workflows/      upstream-sync.yml
├── install.sh
├── packages.txt
├── .sync-ignore
└── README.md
```

---

## Upstream sync

A GitHub Actions workflow (`.github/workflows/`) automatically opens a PR when [isabelroses/dotfiles](https://github.com/isabelroses/dotfiles) cuts a new release. Files listed in `.sync-ignore` are protected and never overwritten by the sync.

---

## Credits

- [isabelroses/dotfiles](https://github.com/isabelroses/dotfiles) — original NixOS config this is ported from
- [Catppuccin](https://github.com/catppuccin/catppuccin) — colour palette
- [Berkeley Mono](https://berkeleygraphics.com/typefaces/berkeley-mono/) — font
