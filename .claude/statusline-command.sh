#!/usr/bin/env bash
# Statusline Claude Code
#   modèle │ dossier │ contexte │ effort │ session 5h │ hebdomadaire 7j
#
# Dépendances : bash (3.2+), jq. Compatible macOS (BSD date) et Linux (GNU date).
# Entrée      : JSON envoyé par Claude Code sur stdin.
# Un segment dont la donnée est absente (ex. rate_limits en mode API) est masqué.

input=$(cat)

# ------------------------------------------------------------------ Couleurs
# ANSI 256, tons moyens (lisibles sur fond sombre et clair).
RST=$'\033[0m'
BOLD=$'\033[1m'
DIM=$'\033[38;5;245m'      # gris neutre : séparateurs, parties vides
C_MODEL=$'\033[38;5;141m'  # violet
C_DIR=$'\033[38;5;75m'     # bleu ciel
C_CTX=$'\033[38;5;73m'     # sarcelle
C_EFFORT=$'\033[38;5;175m' # rose
C_5H=$'\033[38;5;173m'     # orange doux
C_7D=$'\033[38;5;104m'     # pervenche
GRN=$'\033[38;5;71m'       # seuil < 50 %
YEL=$'\033[38;5;179m'      # seuil 50-80 %
RED=$'\033[38;5;167m'      # seuil > 80 %

# ------------------------------------------------------------ Détection d'OS
case "$OSTYPE" in
  darwin*|*bsd*) DATE_FLAVOR=bsd ;;
  *)             DATE_FLAVOR=gnu ;;
esac

# Formate un epoch ($1) avec le format strftime $2 (sans le "+").
# Essaie d'abord la syntaxe de l'OS détecté, puis l'autre (ex. coreutils sous macOS).
fmt_epoch() {
  if [ "$DATE_FLAVOR" = bsd ]; then
    date -r "$1" "+$2" 2>/dev/null || date -d "@$1" "+$2" 2>/dev/null
  else
    date -d "@$1" "+$2" 2>/dev/null || date -r "$1" "+$2" 2>/dev/null
  fi
}

# ------------------------------------------------------- Extraction du JSON
# Un seul appel jq ; séparateur US (0x1f) pour conserver les champs vides.
IFS=$'\x1f' read -r model dir ctx_pct effort five_pct five_reset week_pct week_reset now < <(
  printf '%s' "$input" | jq -r '
    def pct: if . == null then "" else round end;
    def num: if . == null then "" else floor end;
    [
      (.model.display_name // .model.id // ""),
      (.workspace.current_dir // .cwd // ""),
      (.context_window.used_percentage | pct),
      (.effort.level // ""),
      (.rate_limits.five_hour.used_percentage | pct),
      (.rate_limits.five_hour.resets_at | num),
      (.rate_limits.seven_day.used_percentage | pct),
      (.rate_limits.seven_day.resets_at | num),
      (now | floor)
    ] | map(tostring) | join("\u001f")
  ' 2>/dev/null
)

[[ "$now" =~ ^[0-9]+$ ]] || now=$(date +%s)

# ----------------------------------------------------------------- Helpers
# Couleur de seuil -> LC : vert < 50, jaune 50-80, rouge > 80.
level_color() {
  if   (( $1 > 80 )); then LC=$RED
  elif (( $1 >= 50 )); then LC=$YEL
  else                      LC=$GRN
  fi
}

# Barre de $2 glyphes (pleins $3, vides $4) pour le pourcentage $1 -> BAR.
make_bar() {
  local pct=$1 width=$2 full=$3 empty=$4 n i f="" e=""
  n=$(( (pct * width + 50) / 100 ))
  (( n > width )) && n=$width
  (( n < 0 )) && n=0
  level_color "$pct"
  for (( i = 0; i < width; i++ )); do
    if (( i < n )); then f+="$full"; else e+="$empty"; fi
  done
  BAR="${LC}${f}${DIM}${e}${RST}"
}

# Durée en secondes ($1) -> REM, 2 unités max : "3j 4h", "5h 20m", "45m".
fmt_remaining() {
  local s=$1 d h m
  (( s < 0 )) && s=0
  d=$(( s / 86400 ))
  h=$(( s % 86400 / 3600 ))
  m=$(( s % 3600 / 60 ))
  if   (( d > 0 )); then REM="${d}j";  (( h > 0 )) && REM+=" ${h}h"
  elif (( h > 0 )); then REM="${h}h";  (( m > 0 )) && REM+=" ${m}m"
  elif (( m > 0 )); then REM="${m}m"
  else                   REM="<1m"
  fi
}

parts=()

# --------------------------------------------------------------- 1. Modèle
model="${model#Claude }"
model="${model%% (*}"        # "Opus 4.6 (1M context)" -> "Opus 4.6"
[ -z "$model" ] && model="?"
parts+=("${BOLD}${C_MODEL}${model}${RST}")

# ---------------------------------------------------------------- 2. Dossier
if [ -n "$dir" ]; then
  if [ "$dir" = "$HOME" ]; then
    dir="~"
  elif [[ "$dir" == "$HOME"/* ]]; then
    dir="~${dir:${#HOME}}"
  fi
  parts+=("${C_DIR}${dir}${RST}")
fi

# --------------------------------------------------------------- 3. Contexte
if [ -n "$ctx_pct" ]; then
  make_bar "$ctx_pct" 10 "▰" "▱"
  parts+=("${C_CTX}Ctx${RST} ${BAR} ${LC}${ctx_pct}%${RST}")
fi

# ----------------------------------------------------------------- 4. Effort
# effort.level : low | medium | high | xhigh | max. Absent si le modèle ne le gère pas.
if [ -n "$effort" ]; then
  parts+=("${C_EFFORT}Effort ${BOLD}${effort}${RST}")
fi

# ------------------------------------------------------------- 5. Session 5h
if [ -n "$five_pct" ]; then
  make_bar "$five_pct" 5 "●" "○"
  seg="${C_5H}5h${RST} ${BAR} ${LC}${five_pct}%${RST}"
  if [[ "$five_reset" =~ ^[0-9]+$ ]]; then
    reset_time=$(fmt_epoch "$five_reset" "%H:%M")
    fmt_remaining $(( five_reset - now ))
    [ -n "$reset_time" ] && seg+=" ${C_5H}${reset_time}${RST}"
    seg+=" ${C_5H}${REM}${RST}"
  fi
  parts+=("$seg")
fi

# --------------------------------------------------------- 6. Hebdomadaire 7j
if [ -n "$week_pct" ]; then
  make_bar "$week_pct" 5 "●" "○"
  seg="${C_7D}7j${RST} ${BAR} ${LC}${week_pct}%${RST}"
  if [[ "$week_reset" =~ ^[0-9]+$ ]]; then
    fmt_remaining $(( week_reset - now ))
    seg+=" ${C_7D}${REM}${RST}"
    # %u : 1 (lundi) .. 7 (dimanche) ; indépendant de la locale du système.
    reset_date=$(fmt_epoch "$week_reset" "%u %d/%m")   # ex. "1 06/10"
    wd=${reset_date%% *}
    if [[ "$wd" =~ ^[1-7]$ ]]; then
      days=(dim. lun. mar. mer. jeu. ven. sam.)
      seg+=" ${C_7D}${days[wd % 7]} ${reset_date#* }${RST}"
    fi
  fi
  parts+=("$seg")
fi

# ------------------------------------------------------------------ Sortie
sep="${DIM} │ ${RST}"
out=""
for p in "${parts[@]}"; do
  [ -n "$out" ] && out+="$sep"
  out+="$p"
done
printf '%s\n' "$out"
