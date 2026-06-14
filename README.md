<p align="center">
  <img src="docs/banner.svg" alt="xfce4-theme-switcher" width="880"/>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License"/></a>
  <img src="https://img.shields.io/badge/XFCE-4.16%2B-4cadcc.svg" alt="XFCE 4.16+"/>
  <img src="https://img.shields.io/badge/bash-5.0%2B-4EAA25.svg" alt="Bash 5+"/>
  <img src="https://img.shields.io/badge/no%20python%20deps-✓-brightgreen.svg" alt="No Python deps"/>
  <img src="https://img.shields.io/badge/i18n-en%20%7C%20ru%20%7C%20custom-orange.svg" alt="i18n"/>
</p>

---

**xfce4-theme-switcher** is a day/night GTK theme switcher for XFCE with a panel launcher, graphical icon picker, location-aware scheduling, and full i18n.

**The problem:** XFCE has no built-in dark mode schedule. Existing solutions are either genmon plugins requiring manual polling, Python packages with heavy dependencies, or simple scripts with no GUI.

**The solution:** A self-contained bash toolset — a panel launcher with an arrow menu, a graphical settings dialog (yad), reactive icon sync via `gsettings monitor`, and sunrise/sunset scheduling with zero runtime dependencies beyond what ships with a standard XFCE desktop.

---

## Features

| Feature | xfce4-theme-switcher | [xfce4-night-mode](https://github.com/bimlas/xfce4-night-mode) | [AutomaThemely](https://github.com/C2N14/AutomaThemely) | [xfce4-theme-switcher](https://github.com/UdeshyaDhungana/xfce4-theme-switcher) |
|---|:---:|:---:|:---:|:---:|
| Panel launcher with icon | ✅ | GenMon text | ❌ | ❌ |
| Live icon changes day↔night | ✅ | ❌ | ❌ | ❌ |
| Graphical icon picker (96+ icons) | ✅ | ❌ | ❌ | ❌ |
| Icons scaled to panel size | ✅ | ❌ | ❌ | ❌ |
| Time-based schedule | ✅ | ✅ | ✅ | ❌ |
| Sunrise/sunset by location | ✅ | ✅ | ✅ | ❌ |
| City search (OpenStreetMap) | ✅ | ❌ | ❌ | ❌ |
| Terminator terminal theme sync | ✅ | ❌ | ❌ | ❌ |
| Reactive sync (gsettings monitor) | ✅ | ❌ | ❌ | ❌ |
| GUI settings dialog | ✅ | ❌ | ✅ | ❌ |
| Multi-language UI | ✅ en/ru/custom | ❌ | ❌ | ❌ |
| Custom locale files | ✅ | ❌ | ❌ | ❌ |
| No Python/pip dependencies | ✅ | ✅ | ❌ | ✅ |
| One-command install | ✅ | ✅ | ✅ | ❌ |

---

## How it works

```
                      ┌─────────────────────────────────────────┐
                      │         XFCE Panel (plugin-101)         │
                      │  ┌──────────┐  ┌──────────────────────┐ │
                      │  │  ☀/🌙   │  │  ⚙ Theme Settings   │ │
                      │  │ (toggle) │  │  (arrow menu item)   │ │
                      │  └────┬─────┘  └──────────┬───────────┘ │
                      └───────┼────────────────────┼─────────────┘
                              │                    │
              toggle-theme.sh │          theme-settings.sh
                              │                    │
            ┌─────────────────▼────────────────────▼──────────────┐
            │                  GTK Theme switch                    │
            │   xfconf-query + gsettings + xfwm4 theme             │
            └──────────┬──────────────────────────────────────────┘
                       │
         ┌─────────────┼────────────────────┐
         │             │                    │
         ▼             ▼                    ▼
  Terminator    theme-icon-sync.sh    auto-theme.sh
  config copy   (gsettings monitor)   (cron, every min)
  (inotify)     updates panel icon    time or location mode
                  day ☀ / night 🌙       (NOAA sunrise/sunset)
```

### Panel launcher

The launcher lives at `~/.config/xfce4/panel/launcher-101/` and contains two entries:
- **Left item** — toggle between day/night theme instantly
- **Arrow** — opens settings dialog

The panel icon updates reactively via `gsettings monitor org.gnome.desktop.interface` — any theme change from any source (cron, manual, XFCE settings) is detected and the icon switches between ☀ and 🌙.

### Settings dialog

`theme-settings.sh` is a `yad`-based GUI with four sections:

```
┌─────────────────────────────────────────────┐
│  Theme Switcher Settings                    │
├──────────────────────┬──────────────────────┤
│  🌙 Night icon       │  Tango • weather..   │
│  ☀️  Day icon        │  Humanity • clear    │
│  ⏱ Auto-switcher    │  ✓ By location       │
│  🌐 App language     │  English             │
│  🔄 Restart panel    │                      │
│  🔧 Install to panel │                      │
└──────────────────────┴──────────────────────┘
```

**Icon picker** scans all installed icon themes, deduplicates by `(theme, filename)`, renders every icon to panel pixel size via inkscape 2× supersampling, and caches in `~/.cache/theme-switcher/icons/`.

**Auto-switcher** supports two modes:
- **By time** — configurable `DAY_START` / `DAY_END` (e.g. `07:00–18:00`)
- **By location** — NOAA solar algorithm (pure Python stdlib, no third-party packages), city search via Nominatim/OpenStreetMap, IP auto-detection

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
| `python3` | NOAA sunrise/sunset, URL encoding | ✅ |
| `inotifywait` (inotify-tools) | File watching | May need: `apt install inotify-tools` |

No `pip install`, no virtualenvs, no Node.js.

---

## Quick install

```bash
git clone https://github.com/prostopasta/xfce4-theme-switcher.git
cd xfce4-theme-switcher
bash install.sh
```

The installer:
1. Copies scripts to `~/.local/bin/`
2. Installs `.desktop` entries and the moon SVG icon
3. Creates `~/.config/theme-switcher/config` (preserves existing)
4. Deploys `en` and `ru` locale files (preserves custom locales)
5. Enables `theme-icon-sync.service` (systemd --user)
6. Adds cron job for `auto-theme.sh` (every minute)
7. Registers panel launcher as `plugin-101` via xfconf (if XFCE session is active)

---

## Configuration

Config lives at `~/.config/theme-switcher/config`:

```bash
ICON_DAY="weather-clear"                                  # icon name or full path
ICON_NIGHT="/usr/share/icons/Tango/scalable/status/weather-clear-night.svg"
AUTO_SWITCHER="enabled"                                   # enabled | disabled
AUTO_MODE="location"                                      # time | location
DAY_START="07:00"                                         # used in time mode
DAY_END="18:00"
LATITUDE="25.317"                                         # used in location mode
LONGITUDE="55.440"
APP_LANG="en"                                             # en | ru | custom code
```

Edit via `theme-settings.sh` or directly.

---

## Themes used (defaults)

The switcher controls GTK / WM themes via xfconf and gsettings. Default pair:

| Mode | GTK theme | Terminator profile |
|---|---|---|
| Day | `ZorinBlue-Light` | `AdventureTime` colors |
| Night | `Mint-Y-Dark-Aqua` | `dark-Blitz` colors |

Change in `auto-theme.sh` variables `LIGHT_THEME` / `DARK_THEME`.

---

## Adding a custom language

```bash
# Create locale from English template
cp ~/.config/theme-switcher/locales/en.sh ~/.config/theme-switcher/locales/de.sh
# Edit and translate all S_* values
nano ~/.config/theme-switcher/locales/de.sh
# Select in settings
theme-settings.sh → App language → de
```

Or use the built-in button: **App language → ➕ Add language** — it opens the template in your default text editor.

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
| **xfce4-theme-switcher** (this) | — | Shell + yad | ✅ icon+menu | ✅ | ✅ |

---

## License

MIT — see [LICENSE](LICENSE).
