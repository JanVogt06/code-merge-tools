#!/bin/bash

# Konfigurierbare Variablen
OUTPUT_FILE="merged_python_files.py"
SEARCH_DIR="."  # Aktuelles Verzeichnis, kann angepasst werden
SEPARATOR="#================================================================"

# Farben für bessere Ausgabe
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funktion für Hilfe-Anzeige
show_help() {
    echo "Verwendung: $0 [OPTIONEN]"
    echo ""
    echo "Optionen:"
    echo "  -d, --dir PATH       Verzeichnis zum Durchsuchen (Standard: aktuelles Verzeichnis)"
    echo "  -o, --output FILE    Name der Ausgabedatei (Standard: merged_python_files.py)"
    echo "  -r, --recursive      Rekursiv in Unterverzeichnissen suchen"
    echo "  -e, --exclude PATH   Verzeichnisse/Dateien ausschließen (z.B. venv, __pycache__)"
    echo "  -h, --help          Diese Hilfe anzeigen"
    echo ""
    echo "Beispiel: $0 -d ./src -o all_code.py -r -e venv"
}

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
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Zusammengeführte Python Dateien
Erstellt am: $(date)
Suchverzeichnis: $SEARCH_DIR
Rekursiv: $([ -n "$RECURSIVE" ] && echo "Ja" || echo "Nein")
"""

EOF

# Standard-Ausschlüsse für Python hinzufügen
DEFAULT_EXCLUDES=("__pycache__" ".venv" "venv" ".git" ".pytest_cache" ".mypy_cache" "*.pyc" "*.pyo" ".eggs" "dist" "build")
ALL_EXCLUDES=("${DEFAULT_EXCLUDES[@]}" "${EXCLUDES[@]}")

# Zähler für gefundene Dateien
FILE_COUNT=0

# C# Dateien finden und verarbeiten
echo -e "${GREEN}Suche nach Python Dateien in '$SEARCH_DIR'...${NC}"

# Find-Befehl zusammenbauen mit Ausschlüssen
FIND_CMD="find \"$SEARCH_DIR\" -name \"*.py\" -type f"

# Ausschlüsse hinzufügen
for exclude in "${ALL_EXCLUDES[@]}"; do
    FIND_CMD="$FIND_CMD -not -path \"*/$exclude/*\" -not -name \"$exclude\""
done

# Maxdepth wenn nicht rekursiv
if [ -z "$RECURSIVE" ]; then
    FIND_CMD="find \"$SEARCH_DIR\" -maxdepth 1 -name \"*.py\" -type f"
fi

echo -e "${YELLOW}Ausgeschlossen: ${ALL_EXCLUDES[*]}${NC}"
echo ""

# Dateien finden und sortieren
while IFS= read -r file; do
    if [ -f "$file" ]; then
        # Relativen Pfad ermitteln
        REL_PATH=$(realpath --relative-to="$SEARCH_DIR" "$file" 2>/dev/null || echo "$file")
        
        # Überspringe die Ausgabedatei selbst
        if [ "$(basename "$file")" = "$(basename "$OUTPUT_FILE")" ]; then
            continue
        fi
        
        echo -e "  Füge hinzu: ${YELLOW}$REL_PATH${NC}"
        
        # Trennzeichen und Dateiinfo hinzufügen
        {
            echo ""
            echo "$SEPARATOR"
            echo "# Datei: $REL_PATH"
            echo "# Größe: $(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "unbekannt") Bytes"
            echo "# Geändert: $(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$file" 2>/dev/null || stat -c "%y" "$file" 2>/dev/null | cut -d. -f1)"
            echo "$SEPARATOR"
            echo ""
            
            # Dateiinhalt hinzufügen
            cat "$file"
            echo ""
            echo ""
        } >> "$OUTPUT_FILE"
        
        ((FILE_COUNT++))
    fi
done < <(eval "$FIND_CMD | sort")

# Footer hinzufügen
cat >> "$OUTPUT_FILE" << EOF

$SEPARATOR
# Ende der zusammengeführten Dateien
# Anzahl Dateien: $FILE_COUNT
$SEPARATOR
EOF

# Abschlussmeldung
if [ $FILE_COUNT -eq 0 ]; then
    echo -e "${YELLOW}Keine Python Dateien gefunden!${NC}"
    rm -f "$OUTPUT_FILE"
else
    echo ""
    echo -e "${GREEN}Erfolgreich abgeschlossen!${NC}"
    echo -e "  Anzahl Dateien: $FILE_COUNT"
    echo -e "  Ausgabedatei: ${YELLOW}$OUTPUT_FILE${NC}"
    echo -e "  Dateigröße: $(ls -lh "$OUTPUT_FILE" | awk '{print $5}')"
fi