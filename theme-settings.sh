#!/bin/bash
# Theme Switcher Settings — графический диалог настроек.

export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
export DISPLAY=:0

SWITCHER_CONFIG="$HOME/.config/theme-switcher/config"
PANEL_LAUNCHER_DIR="$HOME/.config/xfce4/panel/launcher-101"
APP_DESKTOP="$HOME/.local/share/applications/toggle-theme.desktop"
DARK_THEME="Mint-Y-Dark-Aqua"
ICON_CACHE="$HOME/.cache/theme-switcher/icons"

# Дефолты
ICON_DAY="weather-clear"
ICON_NIGHT="$HOME/.local/share/icons/hicolor/scalable/apps/theme-moon.svg"
AUTO_SWITCHER="enabled"
AUTO_MODE="time"
DAY_START="07:00"
DAY_END="18:00"
LATITUDE=""
LONGITUDE=""
APP_LANG="en"
[ -f "$SWITCHER_CONFIG" ] && source "$SWITCHER_CONFIG"

LOCALES_DIR="$HOME/.config/theme-switcher/locales"

# ── Строки интерфейса ──────────────────────────────────────────────────────
_load_strings() {
    local locale_file="$LOCALES_DIR/${APP_LANG}.sh"
    if [ -f "$locale_file" ]; then
        source "$locale_file"
        return
    fi
    # Встроенный fallback для en и ru если файлы ещё не созданы
    if [ "$APP_LANG" = "ru" ]; then
        S_APP_TITLE="Настройки переключателя тем"
        S_APP_TEXT="<b>Theme Switcher</b> — выберите настройку:"
        S_COL_SETTING="Настройка"; S_COL_VALUE="Значение"
        S_NIGHT_ICON="🌙  Иконка ночи"
        S_DAY_ICON="☀️  Иконка дня"
        S_AUTO="⏱  Авто-переключатель"
        S_LANG="🌐  Язык приложения"
        S_LANG_VALUE="Русский"
        S_AUTO_ON_TIME="✓ По времени"
        S_AUTO_ON_LOC="✓ По локации"
        S_AUTO_OFF="✗ Выключен"
        S_PICKER_NIGHT="Иконка ночного режима"
        S_PICKER_DAY="Иконка дневного режима"
        S_PICKER_COL="Тема  •  Иконка"
        S_PICKER_TEXT="<b>Текущая:</b> %s   <small>(масштабировано до %dpx)</small>"
        S_PICKER_SUBTEXT="Scalable/symbolic — первыми. Поиск по теме:"
        S_LOADING="Загрузка иконок..."
        S_LOADING_PROGRESS="Подготовка: %d/%d"
        S_NO_ICONS="Иконки не найдены."
        S_AUTO_TITLE="Авто-переключатель тем"
        S_AUTO_ENABLE="Включить авто-переключатель"
        S_AUTO_MODE="Режим переключения"
        S_AUTO_MODE_OPTS="По времени!По локации"
        S_AUTO_TIME_HDR="── По времени ───────────"
        S_DAY_FROM="День с (ЧЧ:ММ):"
        S_DAY_TO="День до (ЧЧ:ММ):"
        S_AUTO_LOC_HDR="── По локации ───────────"
        S_LAT="Широта:"; S_LON="Долгота:"
        S_CUR_CITY="Текущий город"
        S_NOT_SET="не задано"
        S_BTN_FIND="🔍 Найти город"
        S_BTN_MAP="🌐 Открыть карту"
        S_BTN_IP="📍 По IP"
        S_AUTO_ENABLED="Авто-переключатель <b>включён</b> (режим: %s)."
        S_AUTO_DISABLED="Авто-переключатель <b>выключен</b>."
        S_CITY_TITLE="Поиск города"
        S_CITY_PROMPT="Введите название города (на любом языке):"
        S_CITY_RESULTS="Выберите город"
        S_CITY_RESULTS_TEXT="Результаты поиска «<b>%s</b>» — выберите нужный:"
        S_CITY_NOT_FOUND="Город «<b>%s</b>» не найден."
        S_CITY_PARSE_ERR="Не удалось разобрать результаты."
        S_IP_ERROR="Не удалось определить локацию по IP."
        S_LANG_TITLE="Язык приложения"
        S_LANG_FIELD="Язык:"
        S_LANG_OPTS="Русский (ru)!English (en)"
        S_LANG_TEXT="Язык интерфейса и результатов поиска городов."
    else
        S_APP_TITLE="Theme Switcher Settings"
        S_APP_TEXT="<b>Theme Switcher</b> — choose a setting:"
        S_COL_SETTING="Setting"; S_COL_VALUE="Value"
        S_NIGHT_ICON="🌙  Night icon"
        S_DAY_ICON="☀️  Day icon"
        S_AUTO="⏱  Auto-switcher"
        S_LANG="🌐  App language"
        S_LANG_VALUE="English"
        S_AUTO_ON_TIME="✓ By time"
        S_AUTO_ON_LOC="✓ By location"
        S_AUTO_OFF="✗ Disabled"
        S_PICKER_NIGHT="Night mode icon"
        S_PICKER_DAY="Day mode icon"
        S_PICKER_COL="Theme  •  Icon"
        S_PICKER_TEXT="<b>Current:</b> %s   <small>(scaled to %dpx)</small>"
        S_PICKER_SUBTEXT="Scalable/symbolic shown first. Search by theme name:"
        S_LOADING="Loading icons..."
        S_LOADING_PROGRESS="Preparing: %d/%d"
        S_NO_ICONS="No icons found."
        S_AUTO_TITLE="Theme Auto-switcher"
        S_AUTO_ENABLE="Enable auto-switcher"
        S_AUTO_MODE="Switching mode"
        S_AUTO_MODE_OPTS="By time!By location"
        S_AUTO_TIME_HDR="── By time ──────────────"
        S_DAY_FROM="Day start (HH:MM):"
        S_DAY_TO="Day end (HH:MM):"
        S_AUTO_LOC_HDR="── By location ──────────"
        S_LAT="Latitude:"; S_LON="Longitude:"
        S_CUR_CITY="Current city"
        S_NOT_SET="not set"
        S_BTN_FIND="🔍 Find city"
        S_BTN_MAP="🌐 Open map"
        S_BTN_IP="📍 Detect by IP"
        S_AUTO_ENABLED="Auto-switcher <b>enabled</b> (mode: %s)."
        S_AUTO_DISABLED="Auto-switcher <b>disabled</b>."
        S_CITY_TITLE="City search"
        S_CITY_PROMPT="Enter city name (any language):"
        S_CITY_RESULTS="Select city"
        S_CITY_RESULTS_TEXT="Results for «<b>%s</b>» — pick one:"
        S_CITY_NOT_FOUND="City «<b>%s</b>» not found."
        S_CITY_PARSE_ERR="Could not parse results."
        S_IP_ERROR="Could not determine location by IP."
        S_LANG_TITLE="App Language"
        S_LANG_FIELD="Language:"
        S_LANG_OPTS="English (en)!Русский (ru)"
        S_LANG_TEXT="UI language and city search results language."
    fi
}
_load_strings

# ── Рестарт панели ──────────────────────────────────────────────────────────
_restart_panel() {
    DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus" \
        DISPLAY=:0 xfce4-panel --restart 2>/dev/null &
}

# ── Автоопределение размера панели ──────────────────────────────────────────
_get_panel_size() {
    local dbus="unix:path=/run/user/$(id -u)/bus"
    for panel in $(DBUS_SESSION_BUS_ADDRESS=$dbus \
                   xfconf-query -c xfce4-panel -l 2>/dev/null \
                   | grep -oE '/panels/panel-[0-9]+/plugin-ids' \
                   | sed 's|/plugin-ids||'); do
        if DBUS_SESSION_BUS_ADDRESS=$dbus \
           xfconf-query -c xfce4-panel -p "${panel}/plugin-ids" 2>/dev/null \
           | grep -qw 101; then
            DBUS_SESSION_BUS_ADDRESS=$dbus \
                xfconf-query -c xfce4-panel -p "${panel}/size" 2>/dev/null \
                && return
        fi
    done
    echo 32
}
PANEL_SIZE=$(_get_panel_size)

_get_fg_color() {
    local theme
    theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'")
    echo "$theme" | grep -qi "dark\|night\|black\|aqua\|mint-y-dark" \
        && echo "#d8d8d8" || echo "#333333"
}
FG_COLOR=$(_get_fg_color)
mkdir -p "$ICON_CACHE"

# ── Рендер иконки ───────────────────────────────────────────────────────────
render_icon() {
    local src=$1
    if [[ "$src" != /* ]]; then
        local found
        found=$(find /usr/share/icons ~/.local/share/icons -name "${src}.svg" \
                     -path "*/scalable/*" 2>/dev/null | head -1)
        found=${found:-$(find /usr/share/icons ~/.local/share/icons \
                              -name "${src}.png" 2>/dev/null | head -1)}
        [ -z "$found" ] && echo "$src" && return
        src="$found"
    fi
    [ -f "$src" ] || { echo "$src"; return; }
    local mtime key cached
    mtime=$(stat -c %Y "$src" 2>/dev/null || echo 0)
    key=$(printf '%s_%s_%s_%s' "$src" "$mtime" "$PANEL_SIZE" "$FG_COLOR" | md5sum | cut -c1-12)
    cached="$ICON_CACHE/${key}.png"
    if [ ! -f "$cached" ]; then
        local render_src="$src"
        if grep -q "currentColor\|ColorScheme" "$src" 2>/dev/null; then
            local tmp_svg; tmp_svg=$(mktemp --suffix=.svg)
            sed "s/currentColor/${FG_COLOR}/g
                 s/\.ColorScheme-Text{color:[^}]*}/\.ColorScheme-Text{color:${FG_COLOR}}/g" \
                "$src" > "$tmp_svg"
            render_src="$tmp_svg"
        fi
        local rs=$(( PANEL_SIZE * 2 ))
        case "$render_src" in
            *.svg|*.SVG)
                inkscape -w "$rs" -h "$rs" --export-type=png \
                    --export-filename="${cached}.tmp.png" "$render_src" 2>/dev/null \
                && convert -resize "${PANEL_SIZE}x${PANEL_SIZE}" \
                       "${cached}.tmp.png" "$cached" 2>/dev/null \
                && rm -f "${cached}.tmp.png" \
                || convert -background none -density 384 \
                       -resize "${PANEL_SIZE}x${PANEL_SIZE}" \
                       "$render_src" "$cached" 2>/dev/null ;;
            *.png|*.PNG)
                convert -resize "${PANEL_SIZE}x${PANEL_SIZE}" \
                    "$render_src" "$cached" 2>/dev/null ;;
        esac
        [ -f "$cached" ] || cp "$src" "$cached" 2>/dev/null
        [ -n "$tmp_svg" ] && rm -f "$tmp_svg"
    fi
    echo "$cached"
}

# ── Сканирование иконок ─────────────────────────────────────────────────────
scan_icons() {
    local pattern=$1 exclude=$2
    python3 - "$pattern" "$exclude" << 'PYEOF'
import sys, os, re, subprocess
pattern = sys.argv[1]; exclude = sys.argv[2] if len(sys.argv) > 2 else ""
noise = ['nightly','MidnightCommander','midnight','fcitx','knights','kicad',
         'firefox','brave','riot','element','godot','thunderbird','atom-night',
         'cloudflare','sunshine','sunpinyin','sunday','sunglasses','bluetooth',
         'bright-red','brightly']
SIZE_RANK = {'scalable':0,'symbolic':1,'64':2,'48':3,'32':4,'24':5,'22':6,'16':7}
def size_rank(p):
    for s,r in SIZE_RANK.items():
        if f'/{s}/' in p or f'/{s}x{s}/' in p: return r
    return 99
def norm_theme(p):
    m = re.search(r'/icons/([^/]+)/', p)
    if not m: return ''
    return re.sub(r'[-_](dark|light|Dark|Light|hidpi|HIDPI|dk|lt)$','',m.group(1))
result = subprocess.run(
    ['find','/usr/share/icons',os.path.expanduser('~/.local/share/icons'),
     '-type','f','(','-name','*.svg','-o','-name','*.png',')'],
    capture_output=True, text=True)
best = {}
for line in result.stdout.splitlines():
    p = line.strip()
    if not p: continue
    if re.search(r'-[0-9]{3}\.(svg|png)$', p): continue
    if not re.search(pattern, p): continue
    if exclude and re.search(exclude, p): continue
    if '.cache' in p: continue
    if any(n in p for n in noise): continue
    if not re.search(r'/(scalable|symbolic|[0-9]+x[0-9]+|[0-9]+)/', p): continue
    theme = norm_theme(p); base = os.path.basename(p); rank = size_rank(p)
    key = (theme, base)
    if key not in best or rank < best[key][0]:
        best[key] = (rank, p)
icons = [v[1] for v in best.values()]
icons.sort(key=lambda p: (size_rank(p), norm_theme(p), os.path.basename(p)))
for p in icons: print(p)
PYEOF
}

icon_label() {
    local path=$1
    local theme file
    theme=$(echo "$path" | sed 's|.*/icons/\([^/]*\)/.*|\1|')
    file=$(basename "$path" | sed 's/\.\(svg\|png\)$//' | sed 's/-symbolic$//')
    echo "${theme}  •  ${file}"
}

# ── Обновление .desktop ─────────────────────────────────────────────────────
update_field() {
    local file=$1 field=$2 value=$3
    [ -f "$file" ] && [ -s "$file" ] || return
    local tmp; tmp=$(mktemp)
    sed "s|^${field}=.*|${field}=${value}|" "$file" > "$tmp"
    [ -s "$tmp" ] && cat "$tmp" > "$file"
    rm -f "$tmp"
}

_cfg_set() {
    local key=$1 val=$2
    if grep -q "^${key}=" "$SWITCHER_CONFIG" 2>/dev/null; then
        sed -i "s|^${key}=.*|${key}=\"${val}\"|" "$SWITCHER_CONFIG"
    else
        echo "${key}=\"${val}\"" >> "$SWITCHER_CONFIG"
    fi
}

apply_icon_now() {
    local icon=$1 kind=$2
    [ "$kind" = "night" ] \
        && sed -i "s|^ICON_NIGHT=.*|ICON_NIGHT=\"${icon}\"|" "$SWITCHER_CONFIG" \
        || sed -i "s|^ICON_DAY=.*|ICON_DAY=\"${icon}\"|"    "$SWITCHER_CONFIG"
    local current_theme is_dark=false should_apply=false
    current_theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'")
    [ "$current_theme" = "$DARK_THEME" ] && is_dark=true
    { $is_dark && [ "$kind" = "night" ]; } && should_apply=true
    { ! $is_dark && [ "$kind" = "day" ]; }  && should_apply=true
    if $should_apply; then
        local tooltip
        $is_dark && tooltip="Ночной режим (нажми чтобы переключить на день)" \
                 || tooltip="Дневной режим (нажми чтобы переключить на ночь)"
        for f in "$PANEL_LAUNCHER_DIR"/*.desktop; do
            [ -f "$f" ] || continue
            grep -q "toggle-theme\|Toggle Theme" "$f" 2>/dev/null || continue
            update_field "$f" "Icon" "$icon"
            update_field "$f" "Comment" "$tooltip"
        done
        update_field "$APP_DESKTOP" "Icon" "$icon"
        update_field "$APP_DESKTOP" "Comment" "$tooltip"
    fi
}

# ── Диалог выбора иконки ────────────────────────────────────────────────────
show_icon_picker() {
    local title=$1 kind=$2 current=$3
    local pattern exclude
    if [ "$kind" = "night" ]; then
        pattern="moon|lunar|crescent|night-light|weather-clear-night|weather-few-clouds-night|weather-clouds-night|stock_weather-night|display-nightcolor"
        exclude="overcast|shower|storm|snow|fog|drizzle|hail|sleet|thunder|mist|sunshine|sunpinyin"
    else
        pattern="weather-clear\.|weather-clear-[^n]|daytime|display-brightness|notification-display-brightness|weather-sunny"
        exclude="nightly|overcast|shower|storm|snow|fog|drizzle|hail|sleet|thunder|mist|cloud|night"
    fi
    local icons=()
    while IFS= read -r line; do [ -n "$line" ] && icons+=("$line"); done \
        < <(scan_icons "$pattern" "$exclude")
    if [ ${#icons[@]} -eq 0 ]; then
        yad --error --text="$S_NO_ICONS" --width=300 2>/dev/null; return
    fi
    local pids=()
    for path in "${icons[@]}"; do render_icon "$path" > /dev/null & pids+=($!); done
    local total=${#icons[@]}
    (
        local done=0
        for pid in "${pids[@]}"; do
            wait "$pid" 2>/dev/null; done=$(( done + 1 ))
            echo $(( done * 100 / total ))
            printf "$S_LOADING_PROGRESS\n" "$done" "$total"
        done
    ) | yad --progress --title="$S_LOADING" --width=380 --auto-close --no-buttons 2>/dev/null
    local rows=()
    for path in "${icons[@]}"; do
        rows+=("$(render_icon "$path")" "$(icon_label "$path")" "$path")
    done
    local picker_text
    picker_text=$(printf "$S_PICKER_TEXT" "$(icon_label "$current")" "$PANEL_SIZE")
    local selected
    selected=$(yad \
        --title="$title" --width=820 --height=620 \
        --list \
        --column=":IMG" --column="$S_PICKER_COL" --column=":HD" \
        --print-column=3 --no-headers --search-column=2 \
        --text="${picker_text}\n${S_PICKER_SUBTEXT}" \
        "${rows[@]}" 2>/dev/null)
    selected="${selected%|}"; [ -z "$selected" ] && return
    apply_icon_now "$selected" "$kind"
    source "$SWITCHER_CONFIG"
}

# ── Геокодинг ───────────────────────────────────────────────────────────────
_reverse_geocode() {
    local lat=$1 lon=$2
    curl -s --max-time 5 -A "theme-switcher/1.0" \
        "https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lon}&format=json&zoom=10&accept-language=${APP_LANG}" \
    | python3 -c "
import sys, json
d = json.load(sys.stdin)
a = d.get('address', {})
city = a.get('city') or a.get('town') or a.get('village') or a.get('county','?')
print(f'{city}, {a.get(\"country\",\"\")}')
" 2>/dev/null
}

_search_city_dialog() {
    local query
    query=$(yad --entry \
        --title="$S_CITY_TITLE" --text="$S_CITY_PROMPT" \
        --entry-text="" --width=400 2>/dev/null)
    [ -z "$query" ] && return
    local encoded url json
    encoded=$(python3 -c "import sys,urllib.parse; print(urllib.parse.quote(sys.argv[1]))" "$query" 2>/dev/null)
    [ -z "$encoded" ] && encoded="$query"
    url="https://nominatim.openstreetmap.org/search?q=${encoded}&format=json&limit=10&addressdetails=1&accept-language=${APP_LANG}"
    json=$(curl -s --max-time 8 -A "theme-switcher/1.0" "$url" 2>/dev/null)
    if [ -z "$json" ] || [ "$json" = "[]" ]; then
        local msg; msg=$(printf "$S_CITY_NOT_FOUND" "$query")
        yad --error --text="$msg" --width=340 2>/dev/null; return
    fi
    local rows=()
    while IFS=$'\t' read -r name coords; do
        rows+=("$name" "$coords")
    done < <(python3 -c "
import sys, json
for item in json.load(sys.stdin):
    print(item['display_name'][:90] + '\t' + item['lat'] + ' ' + item['lon'])
" <<< "$json")
    if [ ${#rows[@]} -eq 0 ]; then
        yad --error --text="$S_CITY_PARSE_ERR" --width=300 2>/dev/null; return
    fi
    local results_text; results_text=$(printf "$S_CITY_RESULTS_TEXT" "$query")
    local selected
    selected=$(yad \
        --title="$S_CITY_RESULTS" --width=700 --height=420 \
        --list --column="$S_COL_SETTING" --column=":HD" \
        --print-column=2 --no-headers --text="$results_text" \
        "${rows[@]}" 2>/dev/null)
    selected="${selected%|}"; [ -z "$selected" ] && return
    echo "$selected" > /tmp/theme-switcher-loc.tmp
}

# ── Диалог авто-переключателя ───────────────────────────────────────────────
show_auto_dialog() {
    source "$SWITCHER_CONFIG"; _load_strings
    local lat="${LATITUDE:-}" lon="${LONGITUDE:-}"
    local city_label="$S_NOT_SET"
    if [ -n "$lat" ] && [ -n "$lon" ]; then
        local city; city=$(_reverse_geocode "$lat" "$lon")
        [ -n "$city" ] && city_label="$city"
    fi
    local sun_preview=""
    if [ -n "$lat" ] && [ -n "$lon" ]; then
        local times; times=$(python3 "$HOME/.local/bin/sunrise-sunset.py" "$lat" "$lon" both 2>/dev/null)
        [ -n "$times" ] && sun_preview="  (☀ $(echo $times | cut -d' ' -f1) — 🌙 $(echo $times | cut -d' ' -f2))"
    fi
    local enabled_val="FALSE"; [ "$AUTO_SWITCHER" = "enabled" ] && enabled_val="TRUE"
    local mode_cb="$S_AUTO_MODE_OPTS"
    [ "${AUTO_MODE:-time}" = "location" ] && {
        local first second
        IFS='!' read -r first second <<< "$S_AUTO_MODE_OPTS"
        mode_cb="${second}!${first}"
    }
    local result
    result=$(yad \
        --title="$S_AUTO_TITLE" --width=460 --height=380 \
        --form --separator="|" \
        --field="${S_AUTO_ENABLE}:CHK"    "$enabled_val" \
        --field="":LBL                    "" \
        --field="${S_AUTO_MODE}:CB"        "$mode_cb" \
        --field="":LBL                    "" \
        --field="${S_AUTO_TIME_HDR}:LBL"  "" \
        --field="${S_DAY_FROM}"           "${DAY_START:-07:00}" \
        --field="${S_DAY_TO}"             "${DAY_END:-18:00}" \
        --field="":LBL                    "" \
        --field="${S_AUTO_LOC_HDR}:LBL"  "" \
        --field="${S_LAT}"               "${lat}" \
        --field="${S_LON}"               "${lon}" \
        --field="${S_CUR_CITY}:LBL"      "${city_label}${sun_preview}" \
        --button="${S_BTN_FIND}!system-search:3" \
        --button="${S_BTN_MAP}!web-browser:4" \
        --button="${S_BTN_IP}!find-location:5" \
        --button="gtk-ok:0" --button="gtk-cancel:1" \
        2>/dev/null)
    local rc=$?
    case $rc in
        3)
            _search_city_dialog
            if [ -f /tmp/theme-switcher-loc.tmp ]; then
                read -r lat lon < /tmp/theme-switcher-loc.tmp
                rm -f /tmp/theme-switcher-loc.tmp
                _cfg_set "LATITUDE" "$lat"; _cfg_set "LONGITUDE" "$lon"
            fi
            show_auto_dialog; return ;;
        4)
            local ml="${lat:-25.317}" mo="${lon:-55.440}"
            xdg-open "https://www.openstreetmap.org/?mlat=${ml}&mlon=${mo}#map=10/${ml}/${mo}" 2>/dev/null &
            show_auto_dialog; return ;;
        5)
            local loc
            loc=$(curl -s --max-time 5 "https://ipapi.co/json/" 2>/dev/null \
                  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['latitude'],d['longitude'])" 2>/dev/null)
            if [ -n "$loc" ]; then
                lat=$(echo "$loc"|cut -d' ' -f1); lon=$(echo "$loc"|cut -d' ' -f2)
                _cfg_set "LATITUDE" "$lat"; _cfg_set "LONGITUDE" "$lon"
            else
                yad --error --text="$S_IP_ERROR" --width=340 2>/dev/null &
            fi
            show_auto_dialog; return ;;
        1|252) return ;;
    esac
    IFS="|" read -r v_enabled _ v_mode _ _ v_start v_end _ _ v_lat v_lon _ <<< "$result"
    local new_enabled="disabled"; [ "$v_enabled" = "TRUE" ] && new_enabled="enabled"
    # Определяем mode по первому варианту в combobox
    local first_opt; IFS='!' read -r first_opt _ <<< "$S_AUTO_MODE_OPTS"
    local new_mode="time"; [ "$v_mode" != "$first_opt" ] && new_mode="location"
    _cfg_set "AUTO_SWITCHER" "$new_enabled"; _cfg_set "AUTO_MODE" "$new_mode"
    _cfg_set "DAY_START" "$v_start";        _cfg_set "DAY_END"   "$v_end"
    [ -n "$v_lat" ] && _cfg_set "LATITUDE"  "$v_lat"
    [ -n "$v_lon" ] && _cfg_set "LONGITUDE" "$v_lon"
    if [ "$new_enabled" = "enabled" ]; then
        crontab -l 2>/dev/null | grep -q 'auto-theme.sh' \
        || (crontab -l 2>/dev/null; echo "*/1 * * * * $HOME/.local/bin/auto-theme.sh") | crontab -
    else
        crontab -l 2>/dev/null | grep -v 'auto-theme.sh' | crontab -
    fi
    [ "$new_enabled" = "enabled" ] && \
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus" DISPLAY=:0 \
        bash "$HOME/.local/bin/auto-theme.sh" &
    local msg; msg=$(printf "$S_AUTO_ENABLED" "$new_mode")
    [ "$new_enabled" != "enabled" ] && msg="$S_AUTO_DISABLED"
    yad --info --text="$msg" --timeout=2 --no-buttons --width=340 2>/dev/null &
}

# ── Диалог выбора языка ─────────────────────────────────────────────────────
show_lang_dialog() {
    source "$SWITCHER_CONFIG"; _load_strings

    # Собираем все доступные локали из файлов
    local rows=() code label
    for f in "$LOCALES_DIR"/*.sh; do
        [ -f "$f" ] || continue
        code=$(basename "$f" .sh)
        # Читаем S_LANG_VALUE из файла локали
        label=$(grep '^S_LANG_VALUE=' "$f" | head -1 | cut -d'"' -f2)
        [ -z "$label" ] && label="$code"
        local mark=""
        [ "$code" = "$APP_LANG" ] && mark=" ✓"
        rows+=("${label}${mark}" "$code")
    done

    local selected
    selected=$(yad \
        --title="$S_LANG_TITLE" --width=400 --height=320 \
        --list \
        --column="$S_COL_SETTING" --column=":HD" \
        --print-column=2 --no-headers \
        --text="$S_LANG_TEXT" \
        "${rows[@]}" \
        --button="➕ Add language!document-new:3" \
        --button="gtk-ok:0" --button="gtk-cancel:1" \
        2>/dev/null)

    local rc=$?

    if [ $rc -eq 3 ]; then
        # Добавить свой язык — открываем en.sh как шаблон в текстовом редакторе
        local new_code
        new_code=$(yad --entry \
            --title="New locale" \
            --text="Enter language code (e.g. de, fr, es, zh):" \
            --entry-text="" --width=340 2>/dev/null)
        [ -z "$new_code" ] && show_lang_dialog && return
        local new_file="$LOCALES_DIR/${new_code}.sh"
        if [ ! -f "$new_file" ]; then
            cp "$LOCALES_DIR/en.sh" "$new_file"
            sed -i "s|^# Theme Switcher locale:.*|# Theme Switcher locale: ${new_code}|" "$new_file"
        fi
        xdg-open "$new_file" 2>/dev/null || \
            yad --text-info --filename="$new_file" \
                --editable --width=600 --height=500 \
                --title="Edit locale: $new_code" \
                --button="gtk-save:0" 2>/dev/null \
            | cat > "$new_file"
        show_lang_dialog; return
    fi

    [ $rc -ne 0 ] && return

    selected="${selected%|}"
    [ -z "$selected" ] && return
    _cfg_set "APP_LANG" "$selected"
    APP_LANG="$selected"
    _load_strings

    # Обновляем Name= в .desktop файлах при смене языка
    local current_theme is_dark=false
    current_theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'")
    [ "$current_theme" = "$DARK_THEME" ] && is_dark=true
    local tcomment
    $is_dark && tcomment="${S_TOGGLE_COMMENT_NIGHT:-Night mode}" \
             || tcomment="${S_TOGGLE_COMMENT_DAY:-Day mode}"
    local tname="${S_TOGGLE_NAME:-Toggle Theme}"
    local sname="${S_SETTINGS_NAME:-Theme Settings}"
    local scomment="${S_SETTINGS_COMMENT:-Settings}"

    for f in "$PANEL_LAUNCHER_DIR/toggle-theme.desktop" \
             "$HOME/.local/share/applications/toggle-theme.desktop"; do
        [ -s "$f" ] || continue
        local tmp; tmp=$(mktemp)
        sed "s|^Name=.*|Name=${tname}|; s|^Comment=.*|Comment=${tcomment}|" "$f" > "$tmp"
        [ -s "$tmp" ] && cat "$tmp" > "$f"; rm -f "$tmp"
    done
    for f in "$PANEL_LAUNCHER_DIR/theme-settings.desktop" \
             "$HOME/.local/share/applications/theme-settings.desktop"; do
        [ -s "$f" ] || continue
        local tmp; tmp=$(mktemp)
        sed "s|^Name=.*|Name=${sname}|; s|^Comment=.*|Comment=${scomment}|" "$f" > "$tmp"
        [ -s "$tmp" ] && cat "$tmp" > "$f"; rm -f "$tmp"
    done

    # Перезапускаем панель чтобы она подхватила новые Name=
    _restart_panel
}

# ── Главный диалог ──────────────────────────────────────────────────────────
show_main_dialog() {
    source "$SWITCHER_CONFIG"; _load_strings
    local auto_label
    if [ "$AUTO_SWITCHER" = "enabled" ]; then
        [ "${AUTO_MODE:-time}" = "location" ] \
            && auto_label="${S_AUTO_ON_LOC} (${LATITUDE:-?}, ${LONGITUDE:-?})" \
            || auto_label="${S_AUTO_ON_TIME} ${DAY_START:-07:00}–${DAY_END:-18:00}"
    else
        auto_label="$S_AUTO_OFF"
    fi
    local action
    action=$(yad \
        --title="$S_APP_TITLE" --width=560 --height=310 \
        --list \
        --column="$S_COL_SETTING" --column="$S_COL_VALUE" --column=":HD" \
        --no-headers --print-column=3 \
        --text="$S_APP_TEXT" \
        "$S_NIGHT_ICON"    "$(icon_label "$ICON_NIGHT")"  "night" \
        "$S_DAY_ICON"      "$(icon_label "$ICON_DAY")"    "day" \
        "$S_AUTO"          "$auto_label"                  "auto" \
        "$S_LANG"          "$S_LANG_VALUE"                "lang" \
        "${S_RESTART:-🔄  Restart panel}"   ""            "restart" \
        "${S_INSTALL_PANEL:-🔧  Install to panel}"  ""   "install" \
        2>/dev/null)
    action="${action%|}"
    case "$action" in
        night)   show_icon_picker "$S_PICKER_NIGHT" "night" "$ICON_NIGHT" ;;
        day)     show_icon_picker "$S_PICKER_DAY"   "day"   "$ICON_DAY"   ;;
        auto)    show_auto_dialog ;;
        lang)    show_lang_dialog ;;
        restart)
            _restart_panel
            yad --info \
                --text="${S_RESTART_DONE:-Panel restarted.}" \
                --timeout=2 --no-buttons --width=280 2>/dev/null &
            ;;
        install)
            bash "$HOME/.local/bin/install-panel-launcher.sh" && \
            _restart_panel && \
            yad --info \
                --text="${S_PANEL_DONE:-Launcher installed.}" \
                --timeout=2 --no-buttons --width=300 2>/dev/null &
            ;;
    esac
}

show_main_dialog
