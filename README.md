<p align="center">
  <img src="docs/banner.svg" alt="xfce-night-switch" width="880"/>
</p>

<p align="center">
  <a href="https://github.com/prostopasta/xfce-night-switch/releases/latest">
    <img src="https://img.shields.io/github/v/release/prostopasta/xfce-night-switch?label=latest&color=4cadcc" alt="Latest release"/>
  </a>
  <a href="https://github.com/prostopasta/xfce-night-switch/releases/latest">
    <img src="https://img.shields.io/github/downloads/prostopasta/xfce-night-switch/total?color=brightgreen" alt="Downloads"/>
  </a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License"/></a>
  <img src="https://img.shields.io/badge/XFCE-4.16%2B-4cadcc.svg" alt="XFCE 4.16+"/>
  <img src="https://img.shields.io/badge/bash-5.0%2B-4EAA25.svg" alt="Bash 5+"/>
  <img src="https://img.shields.io/badge/i18n-en%20%7C%20ru%20%7C%20custom-orange.svg" alt="i18n"/>
</p>

---

**xfce-night-switch** is a day/night GTK theme switcher for XFCE with a panel launcher, graphical settings dialog, Terminator terminal profile sync, location-aware scheduling, and full i18n.

**The problem:** XFCE has no built-in dark mode schedule. Terminator has no way to auto-switch terminal profiles when the system switches between dark and light modes. Existing solutions are either genmon plugins requiring manual polling, Python packages with heavy dependencies, or simple scripts with no GUI.

**The solution:** A self-contained bash toolset — a panel launcher with an arrow menu, a graphical settings dialog (yad) for theme and icon selection, and sunrise/sunset scheduling with zero runtime dependencies beyond what ships with a standard XFCE desktop.

---

## Features

| Feature | xfce-night-switch | [xfce4-night-mode](https://github.com/bimlas/xfce4-night-mode) | [AutomaThemely](https://github.com/C2N14/AutomaThemely) | [xfce4-theme-switcher](https://github.com/UdeshyaDhungana/xfce4-theme-switcher) |
|---|:---:|:---:|:---:|:---:|
| Panel launcher with icon | ✅ | GenMon text | ❌ | ❌ |
| Live icon changes day↔night | ✅ | ❌ | ❌ | ❌ |
| Graphical icon picker (96+ icons) | ✅ | ❌ | ❌ | ❌ |
| GTK theme selector (scans system) | ✅ | ❌ | ❌ | ❌ |
| Terminator profile sync | ✅ | ❌ | ❌ | ❌ |
| Icons scaled to panel size | ✅ | ❌ | ❌ | ❌ |
| Time-based schedule | ✅ | ✅ | ✅ | ❌ |
| Sunrise/sunset by location | ✅ | ✅ | ✅ | ❌ |
| City search (OpenStreetMap) | ✅ | ❌ | ❌ | ❌ |
| GUI settings dialog | ✅ | ❌ | ✅ | ❌ |
| Panel selection (multi-panel) | ✅ | ❌ | ❌ | ❌ |
| Multi-language UI | ✅ en/ru/custom | ❌ | ❌ | ❌ |
| No Python/pip dependencies | ✅ | ✅ | ❌ | ✅ |
| .deb package | ✅ | ❌ | ❌ | ❌ |
| One-command install | ✅ | ✅ | ✅ | ❌ |

---

## Quick install

### Option A — one-liner (Ubuntu / Debian / Mint)

```bash
bash <(curl -fsSL https://github.com/prostopasta/xfce-night-switch/releases/latest/download/install.sh)
```

Checks for missing prerequisites, downloads the latest `.deb`, installs with `sudo dpkg -i`.

### Option B — git clone (any distro / development)

```bash
git clone https://github.com/prostopasta/xfce-night-switch.git
cd xfce-night-switch && bash install.sh
```

Same `install.sh` — auto-detects it's running from a git clone and installs from local source files instead.

To remove:
```bash
sudo dpkg -r xfce-night-switch      # remove (keeps config)
sudo dpkg -P xfce-night-switch      # purge (removes config too)
```

### Prerequisites

Installed automatically by the install script. For manual installs:
```bash
sudo apt install yad curl wget python3 python3-dbus cron
# Optional (for icon rendering in settings):
sudo apt install inkscape imagemagick
```

### Prerequisites

Installed automatically by the install script. For manual installs:
```bash
sudo apt install yad curl wget python3 python3-dbus cron
# Optional (for icon rendering in settings):
sudo apt install inkscape imagemagick
```

---

## How it works

```
                      ┌─────────────────────────────────────────┐
                      │         XFCE Panel (dynamic ID)         │
                      │  ┌──────────┐  ┌──────────────────────┐ │
                      │  │  ☀️/🌙   │  │  ⚙️ Theme Settings   │ │
                      │  │ (toggle) │  │  (arrow menu item)   │ │
                      │  └────┬─────┘  └──────────┬───────────┘ │
                      └───────┼───────────────────┼─────────────┘
                              │                   │
              toggle-theme.sh │ theme-settings.sh │
                              │                   │
            ┌─────────────────▼───────────────────▼────────────────┐
            │                  GTK Theme switch                    │
            │   xfconf-query + gsettings + xfwm4 theme             │
            └──────────┬───────────────────────────────────────────┘
                       │
         ┌─────────────┼────────────────────────────────┐
         │             │                                │
         ▼             ▼                                ▼
  Terminator     Panel icon update              auto-theme.sh
  profile switch  (launcher-N/*.desktop)        (cron, every min)
  (DBus)          day ☀️ / night 🌙            time or location mode
                                                (NOAA sunrise/sunset)
```

### Panel launcher

The launcher is installed at `~/.config/xfce4/panel/launcher-N/` where `N` is a free plugin ID ≥ 100, detected automatically and saved to `~/.config/xfce-night-switch/config`. Two entries:

- **Left item** — toggle between day/night theme instantly
- **Arrow** — opens settings dialog

The panel icon updates on every toggle and every cron run (every minute). If you have multiple panels, the installer detects the one with the clock and places the launcher there. You can move it via **Settings → Panel launcher**.

### Settings dialog

`theme-settings.sh` is a `yad`-based GUI with these sections:

```
┌────────────────────────────────────────────────┐
│  Theme Switcher Settings                       │
├──────────────────────┬─────────────────────────┤
│  🌙 Night icon       │  Tango • weather..      │
│  ☀️ Day icon         │  Humanity • clear       │
│  🎨 Themes           │  [opens theme dialog]   │
│  🖥️ Panel launcher   │  panel-0 (plugin-100)   │
│  ⏱️ Auto-switcher    │  ✓ By location          │
│  🌐 App language     │  English                │
│  🔄 Restart panel    │                         │
└──────────────────────┴─────────────────────────┘
```

**Theme dialog** (`🎨 Themes`) scans `/usr/share/themes/` and `~/.themes/` for installed GTK themes. Pick separate themes for day and night mode. Same for Terminator profiles — reads `~/.config/terminator/config` and lists available profiles.

---

## Terminator profile sync

XFCE has no built-in way to switch Terminator terminal profiles when the system dark/light mode changes. This is a common pain point — Terminator's profiles are static and there is no hook for system theme changes.

**xfce-night-switch solves this** by:

1. Switching the active profile for all open Terminator windows via DBus on every toggle or schedule event
2. Updating the `profile =` setting in layout blocks of `~/.config/terminator/config` so new terminal windows open with the correct profile

**Setup:**

1. Create two profiles in Terminator: **Preferences → Profiles** (e.g. `light-theme` and `dark-theme`)
2. Open **theme-settings → 🎨 Themes** — pick the profiles in the day/night dropdowns
3. Done — Terminator will switch automatically

**If you don't use Terminator**, set both profiles to `default` — no effect.

---

## Requirements

| Package | Used for | Likely pre-installed |
|---|---|---|
| `bash` 5+ | All scripts | ✅ |
| `yad` | Settings GUI | Usually yes on XFCE |
| `xfconf-query` | Panel/XFCE config | ✅ XFCE |
| `gsettings` | GTK theme switching | ✅ GLib |
| `inkscape` | SVG icon rendering | Often yes |
| `imagemagick` (`convert`) | PNG scaling fallback | Usually yes |
| `curl` | City search, IP geolocation | ✅ |
| `python3` | NOAA sunrise/sunset | ✅ |
| `python3-dbus` | Terminator profile switching | `apt install python3-dbus` |

No `pip install`, no virtualenvs, no Node.js.

---

## Configuration

Config lives at `~/.config/xfce-night-switch/config`:

```bash
# GTK themes — use 'theme-settings' GUI to pick from installed themes
LIGHT_THEME="Adwaita"
DARK_THEME="Adwaita-dark"

# Terminator profiles (must match [[ProfileName]] in ~/.config/terminator/config)
TERM_PROFILE_LIGHT="default"
TERM_PROFILE_DARK="default"

# Icons
ICON_DAY="weather-clear"
ICON_NIGHT="$HOME/.local/share/icons/hicolor/scalable/apps/theme-moon.svg"

# Scheduling
AUTO_SWITCHER="enabled"          # enabled | disabled
AUTO_MODE="time"                 # time | location
DAY_START="07:00"
DAY_END="18:00"
LATITUDE=""                      # used in location mode
LONGITUDE=""
APP_LANG="en"                    # en | ru | custom code
```

Edit via `theme-settings` GUI or directly. The file is never overwritten on reinstall.

---

## Adding a custom language

```bash
cp ~/.config/xfce-night-switch/locales/en.sh ~/.config/xfce-night-switch/locales/de.sh
nano ~/.config/xfce-night-switch/locales/de.sh
# Select in settings: App language → de
```

---

## Sunrise/sunset accuracy

`sunrise-sunset.py` uses the [NOAA Solar Calculator](https://gml.noaa.gov/grad/solcalc/) algorithm implemented in pure Python stdlib. Accuracy: ±1 minute for most latitudes. Polar regions (above 66°N / below 66°S) with midnight sun or polar night fall back to time-based mode.

---

## Similar projects

| Project | Stars | Approach | XFCE panel | GUI | Location |
|---|---|---|---|---|---|
| [bimlas/xfce4-night-mode](https://github.com/bimlas/xfce4-night-mode) | 109⭐ | GenMon plugin, shell | Text only | ❌ | ✅ |
| [C2N14/AutomaThemely](https://github.com/C2N14/AutomaThemely) | 202⭐ | Python, multi-DE | ❌ | ✅ | ✅ |
| [UdeshyaDhungana/xfce4-theme-switcher](https://github.com/UdeshyaDhungana/xfce4-theme-switcher) | 10⭐ | Shell | ❌ | ❌ | ❌ |
| **xfce-night-switch** (this) | — | Shell + yad | ✅ icon+menu | ✅ | ✅ |

---

## Contributing

### PR test gate

Every PR automatically gets a test build (`.deb`) and a checklist comment. The checklist is generated by Claude AI based on the diff. To confirm a test, post `/test-passed` — the PR auto-merges.

### AI test plan — configuring the model

The CI uses `ANTHROPIC_API_KEY` + the Anthropic Messages API to generate test checklists. Three repo secrets control this:

| Secret | Default | Description |
|---|---|---|
| `ANTHROPIC_API_KEY` | *(required to enable AI)* | API key for any Anthropic-compatible endpoint |
| `ANTHROPIC_BASE_URL` | `https://api.anthropic.com` | Override for a custom proxy or self-hosted endpoint |
| `ANTHROPIC_MODEL` | `claude-haiku-4-5-20251001` | Any model ID supported by the endpoint |

**Set secrets:** Settings → Secrets and variables → Actions → New repository secret.

**Using a custom endpoint** (e.g. a local proxy, Azure, or a compatible API):
```
ANTHROPIC_BASE_URL = https://your-proxy.example.com
ANTHROPIC_API_KEY  = your-token-here
ANTHROPIC_MODEL    = your-model-id
```

The endpoint must support the [Anthropic Messages API](https://docs.anthropic.com/en/api/messages) format (`POST /v1/messages`). Without `ANTHROPIC_API_KEY`, CI falls back to a diff-based checklist automatically.

### `/test-plan` Claude Code skill

In a git clone with Claude Code, run `/test-plan` to generate a test plan for the current branch and optionally post it as a PR comment.

---

## License

MIT — see [LICENSE](LICENSE).
