#!/bin/bash

# Script zur rekursiven Erfassung der Ordnerstruktur
# Verwendung: ./script.sh [Startverzeichnis] [Ausgabedatei]

# Standardwerte
START_DIR="${1:-.}"
OUTPUT_FILE="${2:-ordnerstruktur.txt}"

# Farben für Terminalausgabe
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}Erfasse Ordnerstruktur von: ${BLUE}$(cd "$START_DIR" && pwd)${NC}"
echo -e "${GREEN}Ausgabedatei: ${BLUE}$OUTPUT_FILE${NC}"
echo ""

# Funktion zur Erstellung der Dokumentation
create_structure_doc() {
    local base_dir="$1"
    local output="$2"
    
    # Konvertiere Ausgabedatei zu absolutem Pfad
    if [[ "$output" != /* ]]; then
        output="$(pwd)/$output"
    fi
    
    # Speichere aktuelles Verzeichnis
    local original_dir="$(pwd)"
    
    # Header für die Dokumentation
    {
        echo "======================================"
        echo "Ordnerstruktur-Dokumentation"
        echo "======================================"
        echo "Startverzeichnis: $(cd "$base_dir" && pwd)"
        echo "Erstellt am: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "======================================"
        echo ""
        echo "Format: [Relativer Pfad] Dateiname"
        echo ""
        echo "======================================"
        echo ""
    } > "$output"
    
    # Wechsle in das Startverzeichnis
    cd "$base_dir" || exit 1
    
    # Zähler für Statistik
    local file_count=0
    local dir_count=0
    
    # Rekursive Erfassung mit find
    while IFS= read -r -d '' file; do
        # Entferne führendes "./"
        relative_path="${file#./}"
        
        if [ -d "$file" ]; then
            # Verzeichnis
            echo "[ORDNER] $relative_path/" >> "$output"
            ((dir_count++))
        else
            # Datei
            filename=$(basename "$file")
            dir_path=$(dirname "$relative_path")
            
            if [ "$dir_path" = "." ]; then
                echo "[DATEI] $filename" >> "$output"
            else
                echo "[DATEI] $relative_path" >> "$output"
            fi
            ((file_count++))
        fi
    done < <(find . -print0 | sort -z)
    
    # Statistik am Ende
    {
        echo ""
        echo "======================================"
        echo "Statistik"
        echo "======================================"
        echo "Anzahl Ordner: $dir_count"
        echo "Anzahl Dateien: $file_count"
        echo "Gesamt: $((file_count + dir_count))"
        echo "======================================"
    } >> "$output"
    
    # Zurück zum ursprünglichen Verzeichnis
    cd "$original_dir"
    
    echo -e "${GREEN}Erfolgreich! Gefunden:${NC}"
    echo "  - Ordner: $dir_count"
    echo "  - Dateien: $file_count"
}

# Alternative kompakte Variante (ohne [DATEI]/[ORDNER] Tags)
create_compact_doc() {
    local base_dir="$1"
    local output="$2"
    
    # Konvertiere Ausgabedatei zu absolutem Pfad
    if [[ "$output" != /* ]]; then
        output="$(pwd)/$output"
    fi
    
    cd "$base_dir" || exit 1
    
    {
        echo "Ordnerstruktur: $(pwd)"
        echo "Erstellt: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "========================================="
        echo ""
        
        find . -type f -o -type d | sed 's|^\./||' | sort
        
        echo ""
        echo "========================================="
        echo "Dateien: $(find . -type f | wc -l | tr -d ' ')"
        echo "Ordner: $(find . -type d | wc -l | tr -d ' ')"
    } > "$output"
}

# Baumstruktur-Variante (visuell wie 'tree' Befehl)
create_tree_doc() {
    local base_dir="$1"
    local output="$2"
    
    # Konvertiere Ausgabedatei zu absolutem Pfad
    if [[ "$output" != /* ]]; then
        output="$(pwd)/$output"
    fi
    
    cd "$base_dir" || exit 1
    
    {
        echo "Baumstruktur: $(pwd)"
        echo "Erstellt: $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        
        # Nutze find mit Formatierung für Baumstruktur
        find . -print | sed -e 's|[^/]*/|  |g' -e 's|^  ||'
        
    } > "$output"
}

# Hauptausführung
echo "Wähle Format:"
echo "1) Detailliert mit Tags [DATEI]/[ORDNER] (Standard)"
echo "2) Kompakte Liste"
echo "3) Baumstruktur"
echo ""
read -p "Auswahl (1-3, Enter für Standard): " choice

case $choice in
    2)
        create_compact_doc "$START_DIR" "$OUTPUT_FILE"
        ;;
    3)
        create_tree_doc "$START_DIR" "$OUTPUT_FILE"
        ;;
    *)
        create_structure_doc "$START_DIR" "$OUTPUT_FILE"
        ;;
esac

echo ""
echo -e "${GREEN}Dokumentation erstellt: ${BLUE}$OUTPUT_FILE${NC}"
echo ""
echo "Vorschau (erste 20 Zeilen):"
echo "======================================"
head -20 "$OUTPUT_FILE"
echo "======================================"