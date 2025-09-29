#!/bin/bash

# Konfigurierbare Variablen
OUTPUT_FILE="merged_web_files.txt"
SEARCH_DIR="."  # Aktuelles Verzeichnis, kann angepasst werden
SEPARATOR="#================================================================"

# Farben für bessere Ausgabe
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Funktion für Hilfe-Anzeige
show_help() {
    echo "Verwendung: $0 [OPTIONEN]"
    echo ""
    echo "Optionen:"
    echo "  -d, --dir PATH       Verzeichnis zum Durchsuchen (Standard: aktuelles Verzeichnis)"
    echo "  -o, --output FILE    Name der Ausgabedatei (Standard: merged_web_files.txt)"
    echo "  -r, --recursive      Rekursiv in Unterverzeichnissen suchen"
    echo "  -e, --exclude PATH   Verzeichnisse/Dateien ausschließen (z.B. node_modules, dist)"
    echo "  -t, --types TYPES    Dateitypen zum Einschließen (Standard: html,css,js)"
    echo "  -h, --help          Diese Hilfe anzeigen"
    echo ""
    echo "Beispiele:"
    echo "  $0 -d ./src -o project_code.txt -r -e node_modules"
    echo "  $0 -r -t 'html,css,js,ts,jsx,tsx,scss'"
}

# Standard-Dateitypen
FILE_TYPES=("html" "css" "js")

# Parameter verarbeiten
RECURSIVE=""
EXCLUDES=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dir)
            SEARCH_DIR="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -r|--recursive)
            RECURSIVE="-r"
            shift
            ;;
        -e|--exclude)
            EXCLUDES+=("$2")
            shift 2
            ;;
        -t|--types)
            IFS=',' read -ra FILE_TYPES <<< "$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Unbekannte Option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Prüfen ob das Suchverzeichnis existiert
if [ ! -d "$SEARCH_DIR" ]; then
    echo -e "${RED}Fehler: Verzeichnis '$SEARCH_DIR' existiert nicht!${NC}"
    exit 1
fi

# Wenn Ausgabedatei bereits existiert, sichern
if [ -f "$OUTPUT_FILE" ]; then
    BACKUP_FILE="${OUTPUT_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${YELLOW}Warnung: '$OUTPUT_FILE' existiert bereits. Erstelle Backup: $BACKUP_FILE${NC}"
    mv "$OUTPUT_FILE" "$BACKUP_FILE"
fi

# Header in die Ausgabedatei schreiben
cat > "$OUTPUT_FILE" << EOF
================================================================================
ZUSAMMENGEFÜHRTE WEB-PROJEKT DATEIEN
================================================================================
Erstellt am: $(date)
Suchverzeichnis: $SEARCH_DIR
Rekursiv: $([ -n "$RECURSIVE" ] && echo "Ja" || echo "Nein")
Dateitypen: ${FILE_TYPES[*]}
================================================================================

EOF

# Standard-Ausschlüsse für Web-Projekte hinzufügen
DEFAULT_EXCLUDES=(
    "node_modules"
    ".git"
    "dist"
    "build"
    ".next"
    ".nuxt"
    "coverage"
    ".cache"
    "vendor"
    "bower_components"
    "*.min.js"
    "*.min.css"
    ".vscode"
    ".idea"
    "package-lock.json"
    "yarn.lock"
)
ALL_EXCLUDES=("${DEFAULT_EXCLUDES[@]}" "${EXCLUDES[@]}")

# Zähler für gefundene Dateien (ohne assoziative Arrays)
TOTAL_COUNT=0
HTML_COUNT=0
CSS_COUNT=0
JS_COUNT=0
TS_COUNT=0
JSON_COUNT=0
OTHER_COUNT=0

# Funktion zum Bestimmen der Syntax-Hervorhebung
get_syntax_type() {
    local ext="${1##*.}"
    case "$ext" in
        html|htm) echo "html" ;;
        css|scss|sass|less) echo "css" ;;
        js|jsx|mjs) echo "javascript" ;;
        ts|tsx) echo "typescript" ;;
        json) echo "json" ;;
        *) echo "text" ;;
    esac
}

# Funktion zum Farbigen Ausgeben basierend auf Dateityp
print_file_type() {
    local file="$1"
    local ext="${file##*.}"
    case "$ext" in
        html|htm) echo -e "${MAGENTA}[HTML]${NC}" ;;
        css|scss|sass|less) echo -e "${BLUE}[CSS]${NC}" ;;
        js|jsx|mjs) echo -e "${YELLOW}[JS]${NC}" ;;
        ts|tsx) echo -e "${CYAN}[TS]${NC}" ;;
        json) echo -e "${GREEN}[JSON]${NC}" ;;
        *) echo -e "[${ext^^}]" ;;
    esac
}

# Funktion zum Erhöhen der Zähler
increment_counter() {
    local ext="$1"
    case "$ext" in
        html|htm) ((HTML_COUNT++)) ;;
        css|scss|sass|less) ((CSS_COUNT++)) ;;
        js|jsx|mjs) ((JS_COUNT++)) ;;
        ts|tsx) ((TS_COUNT++)) ;;
        json) ((JSON_COUNT++)) ;;
        *) ((OTHER_COUNT++)) ;;
    esac
    ((TOTAL_COUNT++))
}

echo -e "${GREEN}Suche nach Web-Dateien in '$SEARCH_DIR'...${NC}"
echo -e "${YELLOW}Ausgeschlossene Pfade: ${ALL_EXCLUDES[*]}${NC}"
echo ""

# Find-Befehl für alle Dateitypen zusammenbauen
FIND_CMD="find \"$SEARCH_DIR\""

# Maxdepth wenn nicht rekursiv
if [ -z "$RECURSIVE" ]; then
    FIND_CMD="$FIND_CMD -maxdepth 1"
fi

# Dateitypen hinzufügen
FIND_CMD="$FIND_CMD \("
FIRST=true
for type in "${FILE_TYPES[@]}"; do
    if [ "$FIRST" = true ]; then
        FIND_CMD="$FIND_CMD -name \"*.${type}\""
        FIRST=false
    else
        FIND_CMD="$FIND_CMD -o -name \"*.${type}\""
    fi
done
FIND_CMD="$FIND_CMD \) -type f"

# Ausschlüsse hinzufügen
for exclude in "${ALL_EXCLUDES[@]}"; do
    FIND_CMD="$FIND_CMD -not -path \"*/$exclude/*\" -not -name \"$exclude\""
done

# Temporäre Datei für sortierte Dateien
TEMP_FILE=$(mktemp)

# Dateien finden und nach Typ gruppieren
while IFS= read -r file; do
    ext="${file##*.}"
    echo "$ext|$file" >> "$TEMP_FILE"
done < <(eval "$FIND_CMD")

# Nach Dateityp sortieren, dann nach Pfad
while IFS='|' read -r ext file; do
    if [ -f "$file" ]; then
        # Relativen Pfad ermitteln (macOS-kompatibel)
        if command -v realpath >/dev/null 2>&1; then
            REL_PATH=$(realpath --relative-to="$SEARCH_DIR" "$file" 2>/dev/null || echo "$file")
        else
            # Fallback für macOS ohne realpath
            REL_PATH="${file#$SEARCH_DIR/}"
            [ "$REL_PATH" = "$file" ] && REL_PATH="$file"
        fi
        
        # Überspringe die Ausgabedatei selbst
        if [ "$(basename "$file")" = "$(basename "$OUTPUT_FILE")" ]; then
            continue
        fi
        
        # Dateityp-Anzeige
        TYPE_DISPLAY=$(print_file_type "$file")
        echo -e "  Füge hinzu: $TYPE_DISPLAY ${CYAN}$REL_PATH${NC}"
        
        # Syntax-Typ bestimmen
        SYNTAX=$(get_syntax_type "$file")
        
        # Dateigröße ermitteln (macOS-kompatibel)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            FILE_SIZE=$(stat -f%z "$file" 2>/dev/null || echo "unbekannt")
            FILE_DATE=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$file" 2>/dev/null || echo "unbekannt")
        else
            FILE_SIZE=$(stat -c%s "$file" 2>/dev/null || echo "unbekannt")
            FILE_DATE=$(stat -c "%y" "$file" 2>/dev/null | cut -d. -f1 || echo "unbekannt")
        fi
        
        # Trennzeichen und Dateiinfo hinzufügen
        {
            echo ""
            echo "$SEPARATOR"
            echo "# Datei: $REL_PATH"
            echo "# Typ: $SYNTAX"
            echo "# Größe: $FILE_SIZE Bytes"
            echo "# Geändert: $FILE_DATE"
            echo "$SEPARATOR"
            echo ""
            
            # Bei größeren Dateien Zeilennummern hinzufügen
            LINE_COUNT=$(wc -l < "$file")
            if [ "$LINE_COUNT" -gt 50 ]; then
                echo "# Zeilen: $LINE_COUNT"
                echo ""
            fi
            
            # Dateiinhalt hinzufügen
            cat "$file"
            echo ""
            echo ""
        } >> "$OUTPUT_FILE"
        
        # Zähler aktualisieren
        increment_counter "$ext"
    fi
done < <(sort -t'|' -k1,1 -k2,2 "$TEMP_FILE")

# Temporäre Datei löschen
rm -f "$TEMP_FILE"

# Statistik-Footer hinzufügen
{
    echo ""
    echo "$SEPARATOR"
    echo "# ZUSAMMENFASSUNG"
    echo "$SEPARATOR"
    echo "# Gesamt: $TOTAL_COUNT Dateien"
    echo "#"
    echo "# Nach Typ:"
    [ $HTML_COUNT -gt 0 ] && echo "#   .html: $HTML_COUNT Dateien"
    [ $CSS_COUNT -gt 0 ] && echo "#   .css: $CSS_COUNT Dateien"
    [ $JS_COUNT -gt 0 ] && echo "#   .js: $JS_COUNT Dateien"
    [ $TS_COUNT -gt 0 ] && echo "#   .ts/tsx: $TS_COUNT Dateien"
    [ $JSON_COUNT -gt 0 ] && echo "#   .json: $JSON_COUNT Dateien"
    [ $OTHER_COUNT -gt 0 ] && echo "#   Andere: $OTHER_COUNT Dateien"
    echo "#"
    echo "# Erstellt: $(date)"
    echo "$SEPARATOR"
} >> "$OUTPUT_FILE"

# Abschlussmeldung
if [ $TOTAL_COUNT -eq 0 ]; then
    echo -e "${YELLOW}Keine Dateien der Typen [${FILE_TYPES[*]}] gefunden!${NC}"
    rm -f "$OUTPUT_FILE"
else
    echo ""
    echo -e "${GREEN}✔ Erfolgreich abgeschlossen!${NC}"
    echo ""
    echo -e "  ${CYAN}Statistik:${NC}"
    echo -e "  ├─ Anzahl Dateien: ${GREEN}$TOTAL_COUNT${NC}"
    [ $HTML_COUNT -gt 0 ] && echo -e "  ├─ ${MAGENTA}[HTML]${NC}: $HTML_COUNT"
    [ $CSS_COUNT -gt 0 ] && echo -e "  ├─ ${BLUE}[CSS]${NC}: $CSS_COUNT"
    [ $JS_COUNT -gt 0 ] && echo -e "  ├─ ${YELLOW}[JS]${NC}: $JS_COUNT"
    [ $TS_COUNT -gt 0 ] && echo -e "  ├─ ${CYAN}[TS]${NC}: $TS_COUNT"
    [ $JSON_COUNT -gt 0 ] && echo -e "  ├─ ${GREEN}[JSON]${NC}: $JSON_COUNT"
    echo -e "  ├─ Ausgabedatei: ${YELLOW}$OUTPUT_FILE${NC}"
    echo -e "  └─ Dateigröße: $(ls -lh "$OUTPUT_FILE" | awk '{print $5}')"
    echo ""
    echo -e "${BLUE}Tipp: Die Datei kann nun einfach mit Claude geteilt werden!${NC}"
fi