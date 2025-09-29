#!/bin/bash

# Konfigurierbare Variablen
OUTPUT_FILE="merged_csharp_files.cs"
SEARCH_DIR="."  # Aktuelles Verzeichnis, kann angepasst werden
SEPARATOR="//================================================================"

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
    echo "  -o, --output FILE    Name der Ausgabedatei (Standard: merged_csharp_files.cs)"
    echo "  -r, --recursive      Rekursiv in Unterverzeichnissen suchen"
    echo "  -h, --help          Diese Hilfe anzeigen"
    echo ""
    echo "Beispiel: $0 -d ./src -o all_code.cs -r"
}

# Parameter verarbeiten
RECURSIVE=""
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
/*
 * Zusammengeführte C# Dateien
 * Erstellt am: $(date)
 * Suchverzeichnis: $SEARCH_DIR
 * Rekursiv: $([ -n "$RECURSIVE" ] && echo "Ja" || echo "Nein")
 */

EOF

# Zähler für gefundene Dateien
FILE_COUNT=0

# C# Dateien finden und verarbeiten
echo -e "${GREEN}Suche nach C# Dateien in '$SEARCH_DIR'...${NC}"

# Find-Befehl zusammenbauen
if [ -n "$RECURSIVE" ]; then
    FIND_CMD="find \"$SEARCH_DIR\" -name \"*.cs\" -type f"
else
    FIND_CMD="find \"$SEARCH_DIR\" -maxdepth 1 -name \"*.cs\" -type f"
fi

# Dateien finden und sortieren
while IFS= read -r file; do
    if [ -f "$file" ]; then
        # Relativen Pfad ermitteln
        REL_PATH=$(realpath --relative-to="$SEARCH_DIR" "$file" 2>/dev/null || echo "$file")
        
        echo -e "  Füge hinzu: ${YELLOW}$REL_PATH${NC}"
        
        # Trennzeichen und Dateiinfo hinzufügen
        {
            echo ""
            echo "$SEPARATOR"
            echo "// Datei: $REL_PATH"
            echo "// Größe: $(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "unbekannt") Bytes"
            echo "// Geändert: $(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$file" 2>/dev/null || stat -c "%y" "$file" 2>/dev/null | cut -d. -f1)"
            echo "$SEPARATOR"
            echo ""
            
            # Dateiinhalt hinzufügen
            cat "$file"
            echo ""
        } >> "$OUTPUT_FILE"
        
        ((FILE_COUNT++))
    fi
done < <(eval "$FIND_CMD | sort")

# Abschlussmeldung
if [ $FILE_COUNT -eq 0 ]; then
    echo -e "${YELLOW}Keine C# Dateien gefunden!${NC}"
    rm -f "$OUTPUT_FILE"
else
    echo ""
    echo -e "${GREEN}Erfolgreich abgeschlossen!${NC}"
    echo -e "  Anzahl Dateien: $FILE_COUNT"
    echo -e "  Ausgabedatei: ${YELLOW}$OUTPUT_FILE${NC}"
    echo -e "  Dateigröße: $(ls -lh "$OUTPUT_FILE" | awk '{print $5}')"
fi