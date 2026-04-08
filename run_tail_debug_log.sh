#!/usr/bin/env bash

set -euo pipefail

echo "📝 Suche debug.log und starte Live-Ansicht..."

# Optional: expliziter Pfad übergeben
if [[ ${1-} != "" ]]; then
  FILE="$1"
  if [[ ! -f "$FILE" ]]; then
    echo "❌ Angegebene Datei nicht gefunden: $FILE"
    exit 1
  fi
  echo "📄 Verwende: $FILE"
  exec tail -n 200 -f "$FILE"
fi

# Standard-Suchpfade (macOS)
SEARCH_DIRS=(
  "$HOME/Library/Application Support"
  "$HOME/Library/Containers"
)

declare -a CANDIDATES=()

for dir in "${SEARCH_DIRS[@]}"; do
  if [[ -d "$dir" ]]; then
    # Suche nach Dateien namens debug.log
    while IFS= read -r -d '' f; do
      CANDIDATES+=("$f")
    done < <(find "$dir" -type f -name debug.log -print0 2>/dev/null || true)
  fi
done

if [[ ${#CANDIDATES[@]} -eq 0 ]]; then
  echo "❌ Keine debug.log gefunden. Starte die App einmal, damit Logs angelegt werden."
  echo "   Tipp: ./run_debug_macos.sh"
  exit 1
fi

# Wähle die zuletzt geänderte Logdatei
LATEST_FILE=""
LATEST_MTIME=0
for f in "${CANDIDATES[@]}"; do
  # macOS/BSD stat
  MTIME=$(stat -f "%m" "$f" 2>/dev/null || echo 0)
  if [[ "$MTIME" -gt "$LATEST_MTIME" ]]; then
    LATEST_MTIME="$MTIME"
    LATEST_FILE="$f"
  fi
done

if [[ -z "$LATEST_FILE" ]]; then
  echo "❌ Konnte keine aktuellste Logdatei bestimmen."
  printf "Gefunden:\n"
  printf ' - %s\n' "${CANDIDATES[@]}"
  exit 1
fi

echo "📄 Folge Logdatei: $LATEST_FILE"
echo "(Beenden mit Ctrl+C)"
tail -n 200 -f "$LATEST_FILE"

